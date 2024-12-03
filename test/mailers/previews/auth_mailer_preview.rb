# Preview all emails at http://localhost:3000/rails/mailers/authentication_mailer
class AuthenticatioPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/authentication_mailer/login_email
  def login_email
    AuthenticatioMailer.login_email
  end
end
