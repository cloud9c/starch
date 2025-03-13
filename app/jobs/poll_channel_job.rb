class PollChannelJob < ApplicationJob
  def perform(channel_id, is_initial_update)
    channel = Channel.find_by(id: channel_id)
    return unless channel

    result = EntryHelper.get_new_and_updated(channel.feed_url, channel.feed_content)

    result[:new].each do |entry_data|
      create_entry(channel, entry_data)
    end

    result[:updated].each do |entry_data|
      update_entry(channel, entry_data)
    end

    return if channel.initial_poll_complete?

    channel.with_lock do
      # double check after locking
      return if channel.initial_poll_complete?

      channel.update(initial_poll_complete: true)

      channel.subscriptions.each do |subscription|
        subscription.add_recent_entries
      end
    end
  end

  def create_entry(channel, entry_data)
    entry = Entry.create(
      channel: channel,
      stable_id: EntryHelper.get_stable_id(channel.feed_url, entry_data),
      fingerprint: EntryHelper.get_fingerprint(entry_data)
    )

    raw_entry_data = EntryHelper.get_raw_entry_data(entry_data)
    document = entry.create_document(raw_entry_data)

    if document.published_at > channel.created_at
      users = entry.channel.users

      document_states = users.map do |user|
        { user_id: user.id, document_id: document.id }
      end

      DocumentState.insert_all!(document_states)

      document.update_search_index

      # warm up extracted document
      ExtractDocumentJob.perform_later(document.id)
    end
  end

  def update_entry(channel, entry_data)
    stable_id = EntryHelper.get_stable_id(channel.feed_url, entry_data)
    existing_entry = Entry.find_by(stable_id: stable_id)
    existing_entry&.update_from_feed(entry_data)
  end
end
