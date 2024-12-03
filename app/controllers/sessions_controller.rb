class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create callback ]
  rate_limit to: 10, within: 3.minutes, only: :create

  def new
  end

  def create
    user = User.find_or_initialize_by(email_address: params[:email_address])

    if user.valid?
      user.save!
      user.send_login_email
      redirect_to new_session_path,
        notice: user.previously_new_record? ? "Check your email to verify your account" : "Check your email to sign in"
    else
      redirect_to new_session_path, alert: user.errors.full_messages.to_sentence
    end
  end

  def callback
    if params[:verification_code].present?
      user = User.find_by_token_for(:verification_code, params[:verification_code])
    else
      user = User.find_by_token_for(:magic_link, params[:magic_link])
    end

    if user
      verified = user.verified_at.nil?

      user.update!(verified_at: Time.current) if !verified

      start_new_session_for user
      
      # redirect_to verified ? after_authentication_url : complete_registration_path
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Invalid link"
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
