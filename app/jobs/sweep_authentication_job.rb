class SweepAuthenticationJob < ApplicationJob
  def perform(*args)
    # destroy expired sessions
    Session.sweep

    # destroy expired or used verification codes
    Verification.sweep

    # destroy unverified users
    User.sweep
  end
end
