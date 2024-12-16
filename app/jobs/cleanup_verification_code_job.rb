class CleanupVerificationCodeJob < ApplicationJob
  def perform(*args)
    # destroy expired or used verification codes
    VerificationCode.sweep
  end
end
