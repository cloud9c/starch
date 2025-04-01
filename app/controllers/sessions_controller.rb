class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create verify ]
  rate_limit to: 10, within: 3.minutes, only: :create
  invisible_captcha only: :create, on_spam: :send_to_root

  def new
    @show_verification = flash[:show_verification]
  end

  def create
    user = User.find_or_initialize_by(email_address: params[:email_address])
    unless user.save
      flash[:alert] = user.errors.full_messages.to_sentence
      redirect_to new_session_path and return
    end

    magic_link_token = user.generate_magic_link
    verification = user.generate_verification

    ### TODO: remove

    if user.email_address === "test@example.com"
      user.verify
      authenticate_session_for(user)
      redirect_to root_path and return
    end

    ###

    unless user.send_login_email(magic_link_token, verification.code)
      flash[:alert] = "We couldn't send your login email at this time. Please try again later."
      redirect_to new_session_path and return
    end

    flash[:show_verification] = true
    redirect_to new_session_path
  end

  def verify
    user = User.find_user_by_params(params[:token], params[:verification_code])

    if user
      user.verify
      authenticate_session_for(user)
      redirect_to root_path and return
    end

    flash[:alert] =
      if params[:token]
        "We were unable to verify you with this link."
      elsif params[:verification_code]
        "There was an error verifying your code."
      end

    flash[:show_verification] = true
    redirect_to new_session_path()
  end

  def destroy
    destroy_session
    redirect_to new_session_path
  end

  def send_to_root
    redirect_to root_path
  end
end
