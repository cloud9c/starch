class SweepAuthenticationJob < ApplicationJob
  def perform(*args)
    Session.expired.destroy_all
    User.unverified.destroy_all
  end
end
