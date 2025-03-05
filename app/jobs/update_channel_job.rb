class UpdateChannelJob < ApplicationJob
  def perform(channel_id, syndicate = true)
    channel = Channel.find_by(id: channel_id)
    return unless channel

    if channel.update_feed_content
      UpdateChannelMetadataJob.perform_now(channel.id)
      PollChannelJob.perform_now(channel.id, syndicate)
    end
  end
end
