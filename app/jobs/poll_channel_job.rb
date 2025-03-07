class PollChannelJob < ApplicationJob
  def perform(channel_id, syndicate)
    channel = Channel.find_by(id: channel_id)
    return unless channel

    result = channel.poll

    return if !syndicate

    ActiveRecord::Base.transaction do
      entries = result[:new].includes(documents: [], channel: { channel_users: :user })

      entries.each do |entry|
        original_doc = entry.documents.find { |d| d.source_type == :rss_original }
        extracted_doc = entry.documents.find { |d| d.source_type == :rss_extracted }

        users = entry.channel.users

        users.each do |user|
          document = user.view_extracted ? extracted_doc : original_doc
          DocumentState.create!(user: user, document: document)
        end
      end
    end
  end
end
