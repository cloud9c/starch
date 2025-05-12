class UpdateChannelsJob < ApplicationJob
  def perform(*args)
    channel_jobs = []
    perform_window = 12.hours
    channel_count = Channel.count
    index = 0
    
    Channel.find_each do |channel|
      delay = index * perform_window / channel_count
      channel_jobs << UpdateChannelJob.new(channel.id).set(wait: delay)
      index += 1
    end
    
    ActiveJob.perform_all_later(channel_jobs)
  end
end
