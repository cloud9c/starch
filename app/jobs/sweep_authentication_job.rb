class SweepAuthenticationJob < ApplicationJob
  def perform(*args)
    Session.sweep
    User.sweep
  end
end
