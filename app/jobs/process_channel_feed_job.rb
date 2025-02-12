class ProcessChannelFeedJob < ApplicationJob
  def perform(channel_id)
    channel = Channel.find_by(id: channel_id)
    return unless channel
    
    channel.poll
  end
end