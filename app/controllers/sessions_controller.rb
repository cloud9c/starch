class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create magic_link ]
  rate_limit to: 10, within: 3.minutes, only: :create

  def new
    @show_verification = session.delete(:show_verification)
  end

  def create
    user = User.find_or_initialize_by(email_address: params[:email_address])

    if user.save
      magic_link_token = user.generate_token_for(:magic_link)
      verification = Verification.create!(user_id: user.id, session_id: resume_session.id)

      user.send_login_email(magic_link_token, verification.code)

      session[:show_verification] = true
      flash[:notice] = user.previously_new_record? ? "Check your email to verify your account" : "Check your email to sign in"
    else
      flash[:alert] = user.errors.full_messages.to_sentence
    end

    redirect_to new_session_path
  end

  def magic_link
    user = find_user_by_params(params)
    return invalid_login_redirect(params) unless user

    handle_user_verification(user)
    authenticate_session_for(user)
    redirect_to root_path
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
      Verification.find_user(resume_session.id, params[:verification_code])
    end
  end

  def invalid_login_redirect(params)
    if params[:token].present?
      flash[:alert] = "We were unable to verify you with this link."
    elsif params[:verification_code].present?
      session[:show_verification] = true
      flash[:alert] = "There was an error verifying your code."
    end
    redirect_to new_session_path
  end

  def handle_user_verification(user)
    return if user.verified_at.present?
    user.update!(verified_at: Time.current)
  end
end
