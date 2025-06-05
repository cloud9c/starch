class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create code verify create_with_passkey passkey_callback ]
  rate_limit to: 10, within: 3.minutes, only: %i[ create verify]
  invisible_captcha only: %i[ create ], on_spam: :send_to_new
  before_action :redirect_if_authenticated, only: %i[ new create code verify ]

  def create
    email = params.expect(:email_address)
    user = User.find_or_initialize_by(email_address: email)

    unless user.save
      return render_reject user.errors.full_messages.to_sentence, :unprocessable_content
    end

    unless user.generate_authentication(session)
      return render_reject "We couldn't send your login email at this time. Please try again later.", :unprocessable_content
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
    webauthn_credential = WebAuthn::Credential.from_get(params)
    user = User.authenticate_by(webauthn_credential:, session:)

    return authenticated_redirect(user) if user

    flash = { alert: "Passkey verification failed" }
    render turbo_stream: turbo_stream.replace(:flash, partial: "shared/flash", locals: { flash: flash })
  end

  def code
    redirect_to new_session_path unless params[:email_address]
  end

  def verify
    user = User.authenticate_by(token: params[:token], verification_code: params[:verification_code], session:)
    return authenticated_redirect(user) if user

    flash[:alert] = if params[:token]
      "We were unable to verify you with this link."
    elsif params[:verification_code]
      "There was an error verifying your code."
    end

    redirect_to code_session_path(email_address: params[:email_address]), status: :see_other
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def send_to_new
    redirect_to new_session_path
  end

  def redirect_if_authenticated
    clear_all_or_redirect_to inbox_path, status: :see_other if authenticated?
  end

  def authenticated_redirect(user)
    start_new_session_for(user)
    clear_all_or_redirect_to "#{after_authentication_url}?format=html", status: :see_other and return
  end

  def render_reject(alert, status)
    flash.now[:alert] = alert
    render :new, status: status
  end
end
