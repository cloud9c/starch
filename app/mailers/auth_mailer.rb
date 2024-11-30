class AuthMailer < ApplicationMailer
  def magic_link(user, token)
    @user = user
    @url = session_url(token: token)
    mail to: user.email_address, subject: "Log in to Starch"
  end
end
