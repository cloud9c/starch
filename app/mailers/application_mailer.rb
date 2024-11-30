class ApplicationMailer < ActionMailer::Base
  default from: "support@@#{Rails.application.credentials.domain}"
  layout "mailer"
end
