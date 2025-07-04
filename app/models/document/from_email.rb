module Document::FromEmail
  extend ActiveSupport::Concern

  def email?
    source.is_a?(EmailSender)
  end

  def sender
    source if email_address?
  end
end
