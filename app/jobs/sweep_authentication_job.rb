class SweepAuthenticationJob < ApplicationJob
  queue_as 0 # queue as highest priority

  def perform(*args)
    # destroy expired sessions
    Session.sweep

    # destroy expired or used verification codes
    Verification.sweep

    # destroy unverified users
    User.sweep
  end
end
