class CleanupSessionJob < ApplicationJob
  queue_as 0 # queue as highest priority

  def perform(*args)
    # destroy expired sessions
    Session.sweep
  end
end
