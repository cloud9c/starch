class UpdateChannelJob < ApplicationJob
  retry_on HTTPX::NativeResolveError, wait: :polynomially_longer, :attempts: 5

  def perform(channel_id)
    Rails.logger.info "Updating channel #{channel_id} at #{Time.now}"
    channel = Channel.find(channel_id)

    if channel.update_feed_content
      UpdateChannelMetadataJob.perform_later(channel.id)
      PollChannelJob.perform_later(channel.id)
    end
  end
end
