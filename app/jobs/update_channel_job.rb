class UpdateChannelJob < ApplicationJob
  def perform
   Channel.find_each do |channel|
     channel.update_metadata
   end
  end
end
