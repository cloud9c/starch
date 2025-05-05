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

    magic_link_token = user.generate_magic_link
    verification_code = user.generate_verification_code

    session[:verification] = {
      user_id: user.id,
      code: verification_code,
      expires_at: 10.minutes.from_now.iso8601
    }

    unless user.send_login_email(magic_link_token, verification_code)
      @flash = { alert: "We couldn't send your login email at this time. Please try again later." }
      return
    end

    redirect_to code_session_path(email_address: email), status: :see_other
  end

  def code
    redirect_to new_session_path unless params[:email_address]
  end

  def verify
    if login(params[:token], params[:verification_code])
      if hotwire_native_app?
        redirect_to redirect_path(url: root_path) and return
      end

      redirect_to "#{after_authentication_url}?format=html", status: :see_other and return
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

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def login(token, verification_code)
    user = if token.present?
      User.find_by_token_for(:magic_link, token)
    elsif verification_code.present?
      verification = session[:verification]
      
      if verification && 
        verification["code"] == verification_code &&
        Time.parse(verification["expires_at"]) > Time.current
        
        user = User.find(verification["user_id"])
        session.delete(:verification)
        user
      else
        nil
      end
    end

    if user
      start_new_session_for(user)
      user.update!(verified_at: Time.current) if user.verified_at.nil?
    end

    return user.present?
  end

  def send_to_new
    redirect_to new_session_path
  end

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end
