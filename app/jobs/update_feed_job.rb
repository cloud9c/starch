class UpdateFeedJob < ApplicationJob
  retry_on HTTPX::NativeResolveError, wait: :polynomially_longer, attempts: 5

  def perform(feed_id)
    Rails.logger.info "Updating feed #{feed_id} at #{Time.now}"
    feed = Feed.find(feed_id)

    if feed.update_content
      UpdateFeedMetadataJob.perform_later(feed.id)
      PollFeedJob.perform_later(feed.id)
    end
  end
end
