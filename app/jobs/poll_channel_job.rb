class PollChannelJob < ApplicationJob
  def perform(channel_id, syndicate)
    channel = Channel.find_by(id: channel_id)
    return unless channel

    result = channel.poll

    return if !syndicate

    result[:new].each do |entry|
      document = entry.documents.find_by!(source_type: 'rss_extracted') # TODO hardcoded
      entry.channel.users.each do |user|
        DocumentUserState.create!(
          user: user,
          document: document
        )
      end
    end
  end
end
