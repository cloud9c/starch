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

    response = HttpHelper.get(self.feed_url, headers)

    return false unless response

    self.polled_at = Time.current
    self.etag = response.headers[:Etag]

    return false if response.status == 304

    self.feed_content = HttpHelper.body_to_s(response)
    save!

    true
  end

  def poll(syndicate)
    result = EntryHelper.get_new_and_updated(self.feed_url, self.feed_content)

    add_new_entries(result[:new], syndicate)
    update_entries(result[:updated])
  end

  def update_metadata
    feed = FeedHelper.parse(self.feed_content) rescue nil
    return unless feed

    attributes = {}

    attributes[:title] = EntryHelper.format_text(feed.title) if feed.respond_to?(:title)
    attributes[:description] = EntryHelper.format_text(feed.description) if feed.respond_to?(:description)
    attributes[:url] = HttpHelper.normalize(
      (feed.url if feed.respond_to?(:url)) || URI(self.feed_url).host
    )
    attributes[:icon] = HttpHelper.get_icon(self.feed_url) if feed.respond_to?(:feed_url)
    attributes[:feed_url] = HttpHelper.normalize feed.feed_url if feed.respond_to?(:feed_url) && feed.feed_url

    update(attributes) unless attributes.empty?
  end

  private

  def schedule_initial_update
    UpdateChannelJob.perform_now(id, syndicate=false)
  end

  def add_new_entries(new_entries, syndicate)
    new_entries.each do |entry|
      Entry.create!(
        channel: self,
        syndicate: syndicate,
        title: EntryHelper.format_text(entry.title),
        description: EntryHelper.format_text(entry.summary),
        author: EntryHelper.format_text(entry.author),
        published_at: entry.published,
        url: HttpHelper.normalize(entry.url),
        content: EntryHelper.format_html(entry.content),
        fingerprint: EntryHelper.get_fingerprint(entry),
        stable_id: EntryHelper.get_stable_id(self.feed_url, entry)
      )
    end
  end

  def update_entries(updated_entries)
    updated_entries.each do |entry|
      stable_id = EntryHelper.get_stable_id(self.feed_url, entry)
      existing_entry = Entry.find_by(stable_id: stable_id)

      if existing_entry
        existing_entry.update!(
          title: EntryHelper.format_text(entry.title),
          description: EntryHelper.format_text(entry.summary),
          author: EntryHelper.format_text(entry.author),
          published_at: entry.published,
          content: EntryHelper.format_html(entry.content),
          fingerprint: EntryHelper.get_fingerprint(entry)
        )
      else
        logger.warn "Could not find existing entry with stable_id: #{stable_id}"
      end
    end
  end
end
