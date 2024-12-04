class AuthenticationMailer < ApplicationMailer
  def login_email(user, token)
    @user = user
    @url = magic_link_session_url(token: token)
    mail to: user.email_address, subject: "Log in to Starch"
  end
end
