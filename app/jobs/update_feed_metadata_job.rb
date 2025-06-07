class UpdateFeedMetadataJob < ApplicationJob
  def perform(feed_id)
    feed = Feed.find_by(id: feed_id)
    return unless feed

    feed.update_metadata
  end
end
