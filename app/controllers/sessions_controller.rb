class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create magic_link ]
  rate_limit to: 10, within: 3.minutes, only: :create

  def new
  end

  def create
    user = User.find_or_initialize_by(email_address: params[:email_address])

    if user.valid?
      user.save!

      magic_link_token = user.generate_token_for(:magic_link)

      vc = VerificationCode.create!(user_id: user.id, session_id: resume_session.id, magic_link_token: magic_link_token)

      user.send_login_email(magic_link_token)

      redirect_to new_session_path,
        notice: user.previously_new_record? ? "Check your email to verify your account" : "Check your email to sign in"
    else
      redirect_to new_session_path, alert: user.errors.full_messages.to_sentence
    end
  end

  def magic_link
    if params[:token].present?
      user = User.find_by_token_for(:magic_link, params[:token])
    elsif params[:verification_code].present?
      user = VerificationCode.find_user(resume_session.id, params[:verification_code])
    end

    if !user
      return redirect_to new_session_path, alert: "Invalid login"
    end

    if params[:token].present?
      code = VerificationCode.get_code(user.id, resume_session.id, params[:token])

      if code
        return redirect_to session_path(verification_code: code)
      else
        VerificationCode.invalidate(user.id, resume_session.id)
      end
    end

    verified = user.verified_at.nil?

    user.update!(verified_at: Time.current) if !verified

    authenticate_session_for user

    # redirect_to verified ? after_authentication_url : complete_registration_path
    redirect_to root_path
  end

  def show
    @verification_code = params[:verification_code]
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
