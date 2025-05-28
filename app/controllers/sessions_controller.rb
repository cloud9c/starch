class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create code verify create_with_passkey passkey_callback ]
  rate_limit to: 10, within: 3.minutes, only: %i[ create verify]
  invisible_captcha only: %i[ create ], on_spam: :send_to_new
  before_action :redirect_if_authenticated, only: %i[ new create code verify ]

  def create
    email = params.expect(:email_address)
    user = User.find_or_initialize_by(email_address: email)

    unless user.save
      flash = { alert: user.errors.full_messages.to_sentence }
      render turbo_stream: turbo_stream.replace(:flash, partial: "shared/flash", locals: { flash: flash }) and return
    end

    magic_link_token = user.generate_magic_link
    verification_code = user.generate_verification_code

    session[:verification] = {
      code: verification_code,
      token: magic_link_token
    }

    unless user.send_login_email(magic_link_token, verification_code)
      flash = { alert: "We couldn't send your login email at this time. Please try again later." }
      render turbo_stream: turbo_stream.replace(:flash, partial: "shared/flash", locals: { flash: flash }) and return
    end

    redirect_to code_session_path(email_address: email), status: :see_other
  end

  def create_with_passkey
    get_options = WebAuthn::Credential.options_for_get(
      user_verification: "required"
    )

    session[:current_authentication] = {
      challenge: get_options.challenge
    }

    render json: get_options
  end

  def passkey_callback
    begin
      webauthn_credential = WebAuthn::Credential.from_get(params)

      if login(nil, nil, webauthn_credential)
        clear_all_or_redirect_to "#{after_authentication_url}?format=html", status: :see_other and return
      end
    rescue WebAuthn::Error => e
      flash = { alert: "Verification failed" }
      render turbo_stream: turbo_stream.replace(:flash, partial: "shared/flash", locals: { flash: flash }) and return
    ensure
      session.delete(:current_authentication)
    end
  end

  def code
    redirect_to new_session_path unless params[:email_address]
  end

  def verify
    if login(params[:token], params[:verification_code])
      clear_all_or_redirect_to "#{after_authentication_url}?format=html", status: :see_other and return
    end

    flash = {
      alert:  if params[:token]
        "We were unable to verify you with this link."
              elsif params[:verification_code]
        "There was an error verifying your code."
              end
    }

    respond_to do |format|
      format.html {
        flash[:alert] = flash[:alert]
        redirect_to new_session_path
      }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(:flash, partial: "shared/flash", locals: { flash: flash })
      }
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def login(token, verification_code, webauthn_credential=nil)
    user = if token.present?
      User.find_by_token_for(:magic_link, token)
    elsif verification_code.present?
      verification = session[:verification]

      if verification && verification["code"] == verification_code
        session.delete(:verification)
        User.find_by_token_for(:magic_link, verification["token"])
      end
    elsif webauthn_credential.present?
      user_handle = webauthn_credential.user_handle
      user = User.find_by(webauthn_id: user_handle)
      credential = user.webauthn_credentials.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))

      webauthn_credential.verify(
        session[:current_authentication]["challenge"],
        public_key: credential.public_key,
        sign_count: credential.sign_count,
        user_verification: true,
      )

      credential.update!(sign_count: webauthn_credential.sign_count)

      user
    end

    return false unless user

    start_new_session_for(user)
    user.update!(verified_at: Time.current)
    true
  end

  def send_to_new
    redirect_to new_session_path
  end

  def redirect_if_authenticated
    clear_all_or_redirect_to inbox_path, status: :see_other if authenticated?
  end
end
