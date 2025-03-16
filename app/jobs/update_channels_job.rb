class UpdateChannelsJob < ApplicationJob
  def perform
    Channel.find_each do |channel|
      delay = rand(0..12).hours.to_i

      UpdateChannelJob.set(wait: delay).perform_later(channel.id, false)
    end
  end
end
