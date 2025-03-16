class UpdateChannelJob < ApplicationJob
  def perform(channel_id, is_initial_update = false)
    channel = Channel.find_by(id: channel_id)
    return unless channel

    if channel.update_feed_content
      UpdateChannelMetadataJob.perform_later(channel.id)
      PollChannelJob.perform_later(channel.id, is_initial_update)
    end
  end
end
