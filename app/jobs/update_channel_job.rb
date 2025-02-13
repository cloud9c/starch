class UpdateChannelJob < ApplicationJob
  def perform(channel_id, initial = true)
    channel = Channel.find_by(id: channel_id)
    return unless channel

    if channel.update_feed_content
      UpdateChannelMetadataJob.perform_later(channel.id)
      PollChannelJob.perform_later(channel.id, initial)
    end
  end
end
