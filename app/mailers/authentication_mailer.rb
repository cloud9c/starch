class AuthenticationMailer < ApplicationMailer
  def login_email(user, magic_link_token, verification_code)
    @user = user
    @url = magic_link_session_url(token: magic_link_token)
    @verification_code = verification_code.code
    mail to: user.email_address, subject: "Secure link to log in to Starch | #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
  end
end
