class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create magic_link ]
  rate_limit to: 10, within: 3.minutes, only: :create

  def new
    @show_verification = session.delete(:show_verification)
  end

  def create
    user = User.find_or_initialize_by(email_address: params[:email_address])

    if user.valid?
      user.save!

      magic_link_token = user.generate_token_for(:magic_link)
      verification_code = VerificationCode.create!(user_id: user.id, session_id: resume_session.id)

      user.send_login_email(magic_link_token, verification_code)

      session[:show_verification] = true
      redirect_to new_session_path,
        notice: user.previously_new_record? ? "Check your email to verify your account" : "Check your email to sign in"
    else
      redirect_to new_session_path, alert: user.errors.full_messages.to_sentence
    end
  end

  def magic_link
    user = find_user_by_params(params)
    return invalid_login_redirect(params) unless user

    handle_user_verification(user)
    authenticate_session_for(user)
    redirect_to root_path
  end

  def show
    @verification_code = params[:verification_code]
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def find_user_by_params(params)
    if params[:token].present?
      User.find_by_token_for(:magic_link, params[:token])
    elsif params[:verification_code].present?
      VerificationCode.find_user(resume_session.id, params[:verification_code])
    end
  end

  def invalid_login_redirect(params)
    if params[:token].present?
      redirect_to new_session_path, alert: "We were unable to verify you with this link."
    elsif params[:verification_code].present?
      session[:show_verification] = true
      redirect_to new_session_path, alert: "There was an error verifying your code."
    end
  end

  def handle_user_verification(user)
    return if user.verified_at.present?
    user.update!(verified_at: Time.current)
  end
end
