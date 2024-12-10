class CleanupVerificationCodeJob < ApplicationJob
  queue_as 0 # queue as highest priority

  def perform(*args)
    # destroy expired or used verification codes
    VerificationCode.sweep
  end
end
