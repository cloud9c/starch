class UpdateChannelsJob < ApplicationJob
  def perform(immediate: false)
    Channel.find_each do |channel|
      if immediate
        # Perform immediately with no delay
        UpdateChannelJob.perform_later(channel.id)
      else
        # Use random delay as before
        delay = rand(0..12).hours.to_i
        UpdateChannelJob.set(wait: delay).perform_later(channel.id)
      end
    end
  end
end
