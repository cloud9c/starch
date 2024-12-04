class AuthenticationMailer < ApplicationMailer
  def login_email(user, token)
    @user = user
    @url = magic_link_session_url(token: token)
    mail to: user.email_address, subject: "Secure link to log in to Starch | #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
  end
end
