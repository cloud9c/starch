class Channel < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :documents, through: :entries, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :feed_url, presence: true, uniqueness: true

  after_create :schedule_initial_update

  def update_feed_content
    headers = {}
    headers["If-Modified-Since"] = self.polled_at.httpdate if self.polled_at
    headers["If-None-Match"] = self.etag if self.etag

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(self.feed_url, headers: headers)
    response.raise_for_status

    self.polled_at = Time.current
    self.etag = response.headers[:Etag]

    return false if response.status == 304

    self.feed_content = ChannelUtils.body_to_s(response)
    save!

    true
  end

  def update_metadata
    feed = ChannelUtils.parse_feed(self.feed_content) rescue nil
    return unless feed

    feed_url = UrlUtils.normalize(feed.try(:feed_url) || self.feed_url).to_s

    url = UrlUtils.normalize(
      feed.try(:url) || UrlUtils.get_origin(UrlUtils.normalize(feed_url))
    ).to_s

    attributes = {
      title: EntryUtils.format_text(feed.try(:title)),
      description: EntryUtils.format_text(feed.try(:description)),
      feed_url: feed_url,
      url: url,
      icon: ChannelUtils.get_icon(url)
    }.compact

    update(attributes) unless attributes.empty?
  end

  def poll
    result = EntryUtils.get_new_and_updated(self.feed_url, self.feed_content)

    result[:new].each do |entry_data|
      self.create_entry(entry_data)
    end

    result[:updated].each do |entry_data|
      self.update_entry(entry_data)
    end

    # initial polling logic
    return if self.initial_poll_complete?

    self.with_lock do
      # double check after locking
      return if self.initial_poll_complete?

      self.update(initial_poll_complete: true)

      self.subscriptions.to_inbox.each do |subscription|
        subscription.add_recent_entries
      end
    end
  end

  private

  def schedule_initial_update
    UpdateChannelJob.perform_now(id)
  end

  def create_entry(entry_data)
    entry = self.entries.create(
      stable_id: EntryUtils.get_stable_id(self.feed_url, entry_data),
      fingerprint: EntryUtils.get_fingerprint(entry_data)
    )

    raw_entry_data = EntryUtils.get_raw_entry_data(entry_data)
    document = entry.create_document(raw_entry_data)

    if document.published_at > self.created_at
      users = entry.channel.subscriptions.to_inbox.map(&:user).uniq

      document_states = users.map do |user|
        { user_id: user.id, document_id: document.id }
      end

      # warm up extracted document
      ExtractDocumentJob.perform_later(document.id)

      DocumentState.insert_all!(document_states)
      document.update_search_index
    end
  end

  def update_entry(entry_data)
    stable_id = EntryUtils.get_stable_id(self.feed_url, entry_data)
    existing_entry = Entry.find_by(stable_id: stable_id)
    existing_entry&.update_from_feed(entry_data)
  end
end
