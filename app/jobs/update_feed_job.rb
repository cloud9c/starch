class UpdateFeedJob < ApplicationJob
  retry_on HTTPX::NativeResolveError, wait: :polynomially_longer, attempts: 5

  def perform(feed_id)
    feed = Feed.find(feed_id)

    if feed.polled_at.nil? || feed.polled_at < 7.days.ago
      feed.update_metadata
    end

    feed.poll if feed.update_content
  end
end
