class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create code verify ]
  rate_limit to: 10, within: 3.minutes, only: :create
  invisible_captcha only: :create, on_spam: :send_to_root
  before_action :redirect_if_authenticated, except: [:destroy]

  def create
    email = params.require(:session).permit(:email_address)[:email_address]
    user = User.find_or_initialize_by(email_address: email)

    unless user.save
      @flash = {:alert => user.errors.full_messages.to_sentence}
      return
    end

    magic_link_token = user.generate_magic_link
    verification = user.generate_verification

    ### TODO: remove
    if user.email_address === "test@example.com"
      user.verify
      authenticate_session_for(user)

      redirect_url = url_from(session[:redirect_url]) || root_path
      session.delete(:redirect_url)
      refresh_or_redirect_to "#{redirect_url}?format=html", status: :see_other and return
    end
    ###

    unless user.send_login_email(magic_link_token, verification.code)
      @flash = {:alert => "We couldn't send your login email at this time. Please try again later."}
      return
    end

    redirect_to code_session_path(email_address: email), status: :see_other
  end

  def code
    redirect_to new_session_path unless params[:email_address]
  end

  def verify
    user = User.find_user_by_params(params[:token], params[:verification_code])

    if user
      user.verify
      authenticate_session_for(user)
      
      redirect_url = url_from(session[:redirect_url]) || root_path
      session.delete(:redirect_url)
      refresh_or_redirect_to "#{redirect_url}?format=html", status: :see_other and return
    end

    @flash = {
      :alert =>
      if params[:token]
        "We were unable to verify you with this link."
      elsif params[:verification_code]
        "There was an error verifying your code."
      end
    }
  end

  def destroy
    destroy_session
    redirect_to new_session_path
  end

  private

  def send_to_root
    redirect_to root_path
  end

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end
