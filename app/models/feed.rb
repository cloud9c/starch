class Feed < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :documents, through: :entries, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :feed_url, presence: true, uniqueness: true

  after_create :schedule_initial_update

  def update_content
    headers = {}
    headers["If-Modified-Since"] = polled_at.httpdate if polled_at.present?
    headers["If-None-Match"] = etag if etag.present?

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(feed_url, headers: headers)
    response.raise_for_status

    update(polled_at: Time.current, etag: response.headers[:Etag])

    return false if response.status == 304

    response_body = response.body.to_s.force_encoding("UTF-8")

    update(content: response_body)

    true
  end

  def update_metadata
    feed = FeedUtils.parse_feed(content) rescue nil
    return unless feed

    feed_url = UrlUtils.normalize(feed.try(:feed_url)) || feed_url

    site_url = UrlUtils.normalize(feed.try(:url)) || UrlUtils.get_origin(feed_url)

    attributes = {
      title: EntryUtils.format_text(feed.try(:title)),
      description: EntryUtils.format_text(feed.try(:description)),
      feed_url: feed_url,
      url: site_url,
      icon: get_icon(site_url)
    }.compact

    update(attributes) unless attributes.empty?
  end

  def poll
    result = EntryUtils.get_new_and_updated(feed_url, content)

    result[:new].each do |entry_data|
      create_entry(entry_data)
    end

    result[:updated].each do |entry_data|
      update_entry(entry_data)
    end

    with_lock do
      return if initial_poll_complete?

      update(initial_poll_complete: true)

      subscriptions.to_inbox.each do |subscription|
        subscription.add_recent_entries
      end
    end
  end

  private

  def schedule_initial_update
    UpdateFeedJob.perform_now(id)
  end

  def create_entry(entry_data)
    entry = entries.create(
      stable_id: EntryUtils.get_stable_id(feed_url, entry_data),
      fingerprint: EntryUtils.get_fingerprint(entry_data)
    )

    raw_entry_data = EntryUtils.get_raw_entry_data(entry_data)
    document = Document.create!(raw_entry_data.merge(source: entry))

    if document.published_at > created_at
      users = entry.feed.subscriptions.to_inbox.map(&:user).uniq

      document_states = users.map do |user|
        { user_id: user.id, document_id: document.id, status: :inbox }
      end

      # warm up extracted document
      ExtractDocumentJob.perform_later(document.id)

      DocumentState.insert_all!(document_states)
      document.update_search_index
    end
  end

  def update_entry(entry_data)
    stable_id = EntryUtils.get_stable_id(feed_url, entry_data)
    existing_entry = Entry.find_by(stable_id: stable_id)
    existing_entry&.update_from_feed(entry_data)
  end

  def get_icon(base_url)
    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(base_url)
    return nil if response.error

    body = response.body.to_s.force_encoding("UTF-8")

    doc = Nokogiri::HTML(body)
    icon_url = doc.css('link[rel~="apple-touch-icon"], link[rel~="icon"]').map { |link| link[:href] }.first
    icon_url ||= "/favicon.ico"

    URI.join(base_url, icon_url).to_s rescue nil
  end
end
