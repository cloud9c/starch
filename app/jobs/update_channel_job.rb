class UpdateChannelJob < ApplicationJob
  def perform(channel_id)
    channel = Channel.find_by(id: channel_id)
    return unless channel
    
    puts "UPDATING CHANNEL #{channel.url}"

    if channel.update_feed_content
      puts "UPDATING METDATA AND POLLING FEED #{channel.url}"

      UpdateChannelMetadataJob.perform_later(channel.id)
      ProcessChannelFeedJob.perform_later(channel.id)
    end
  end
end
