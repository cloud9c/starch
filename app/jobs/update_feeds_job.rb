class UpdateFeedsJob < ApplicationJob
  def perform(*args)
    feed_jobs = []
    perform_window = 12.hours
    feed_count = Feed.count
    index = 0

    Feed.find_each do |feed|
      delay = index * perform_window / feed_count
      feed_jobs << UpdateFeedJob.new(feed.id).set(wait: delay)
      index += 1
    end

    ActiveJob.perform_all_later(feed_jobs)
  end
end
