class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create code verify ]
  rate_limit to: 10, within: 3.minutes, only: %i[ create verify]
  invisible_captcha only: %i[ create ], on_spam: :send_to_new
  before_action :redirect_if_authenticated, only: %i[ new create code verify ]

  def create
    email = params.expect(:email_address)
    user = User.find_or_initialize_by(email_address: email)

    unless user.save
      @flash = { alert: user.errors.full_messages.to_sentence }
      return
    end

    generate_verification_for(user)

    redirect_to code_session_path(email_address: email), status: :see_other
  end

  def code
    redirect_to new_session_path unless params[:email_address]
  end

  def verify
    if verify_session(params[:token], params[:verification_code])
      redirect_to authenticated_session_path and return
    end

    @flash = {
      alert:  if params[:token]
        "We were unable to verify you with this link."
              elsif params[:verification_code]
        "There was an error verifying your code."
              end
    }

    respond_to do |format|
      format.html {
        flash[:alert] = @flash[:alert]
        redirect_to new_session_path
      }
      format.turbo_stream
    end
  end

  def authenticated
    if hotwire_native_app?
      redirect_to redirect_path(url: root_path) and return
    end

    redirect_url = url_from(session[:redirect_url]) || inbox_path
    session.delete(:redirect_url)
    redirect_to "#{redirect_url}?format=html", status: :see_other and return
  end

  def destroy
    destroy_session
    redirect_to new_session_path
  end

  private

  def send_to_new
    redirect_to new_session_path
  end

  def redirect_if_authenticated
    redirect_to authenticated_session_path if authenticated?
  end

  def generate_verification_for(user)
    magic_link_token = user.generate_magic_link
    verification = user.generate_verification

    unless user.send_login_email(magic_link_token, verification.code)
      @flash = { alert: "We couldn't send your login email at this time. Please try again later." }
    end
  end

  def verify_session(token, verification_code)
    user = if token.present?
      User.find_by_token_for(:magic_link, token)
    elsif verification_code.present?
      Verification.find_user(Current.session.id, verification_code)
    end

    if user.present?
      resume_session && Current.session.update!(user: user)
      user.update!(verified_at: Time.current)
    end

    user.present?
  end
end
