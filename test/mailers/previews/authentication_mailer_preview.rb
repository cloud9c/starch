# Preview all emails at http://localhost:3000/rails/mailers/authentication_mailer
class AuthenticationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/authentication_mailer/login_email
  def login_email
    AuthenticationMailer.login_email
  end
end
