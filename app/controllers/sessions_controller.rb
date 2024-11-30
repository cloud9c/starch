class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      user.send_magic_link
      redirect_to new_session_path, notice: "Check your email"
    else
      redirect_to new_session_path, alert: "Email not found"
    end
  end

  def callback
    if user = User.find_by_login_token(params[:token])
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Invalid link"
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
