class UpdateChannelMetadataJob < ApplicationJob
  def perform(channel_id)
    channel = Channel.find_by(id: channel_id)
    return unless channel
    
    channel.update_metadata
  end
end