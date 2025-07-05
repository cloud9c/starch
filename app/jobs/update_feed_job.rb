class UpdateFeedJob < ApplicationJob
  retry_on HTTPX::NativeResolveError, wait: :polynomially_longer, attempts: 5

  def perform(feed_id)
    feed = Feed.find(feed_id)
    feed.poll
  end
end
