class AuthenticationMailer < ApplicationMailer
  def login_email(user, magic_link_token, verification_code)
    @user = user
    @url = magic_link_session_url(token: magic_link_token)
    @verification_code = verification_code

    mail to: user.email_address, subject: "Log in to Starch (#{verification_code})"
  end
end
