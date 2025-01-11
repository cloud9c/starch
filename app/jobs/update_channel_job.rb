class UpdateChannelJob < ApplicationJob
  def perform(channel_id)
    channel = Channel.find_by(id: channel_id)
    return unless channel # Guard against deleted channels

    channel.update_feed_content
  end
end
