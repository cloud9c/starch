class AuthenticationMailer < ApplicationMailer
  def login_email
    user = params[:user]
    @magic_link_url = verify_session_url(token: params[:magic_link_token])
    @verification_code = params[:verification_code]

    mail(to: user.email_address, subject: "Log in to Starch (#{@verification_code})")
  end
end
