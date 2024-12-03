class AuthenticationMailer < ApplicationMailer
  def login_email(user, magic_link, verification_code)
    @user = user
    @url = session_callback_url(magic_link: magic_link)
    @verification_code = verification_code
    mail to: user.email_address, subject: "Log in to Starch"
  end
end
