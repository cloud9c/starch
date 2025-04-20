class UpdateChannelJob < ApplicationJob
  def perform(channel_id)
    channel = Channel.find!(channel_id)

    if channel.update_feed_content
      UpdateChannelMetadataJob.perform_later(channel.id)
      PollChannelJob.perform_later(channel.id)
    end
  end
end
