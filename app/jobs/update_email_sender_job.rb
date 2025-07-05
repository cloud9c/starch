class UpdateEmailSenderJob < ApplicationJob
  retry_on HTTPX::NativeResolveError, wait: :polynomially_longer, attempts: 5

  def perform(feed_id)
    email_sender = EmailSender.find(feed_id)
    email_sender.update_metadata
  end
end
