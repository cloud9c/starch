class PollChannelJob < ApplicationJob
  def perform(channel_id, syndicate)
    channel = Channel.find_by(id: channel_id)
    return unless channel
    
    channel.poll(syndicate)
  end
end