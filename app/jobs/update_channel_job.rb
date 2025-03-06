class UpdateChannelJob < ApplicationJob
  def perform(channel_id, syndicate = true)
    channel = Channel.find_by(id: channel_id)
    return unless channel

    if channel.update_feed_content
      perform_method = syndicate ? :perform_later : :perform_now # TODO ideally we dont do this
      UpdateChannelMetadataJob.send(perform_method, channel.id)
      PollChannelJob.send(perform_method, channel.id, syndicate)
    end
  end
end
