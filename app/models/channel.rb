class Channel < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :documents, through: :entries, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :feed_url, presence: true, uniqueness: true
  after_validation :update_feed_content

  after_save :update_metadata, if: :saved_change_to_feed_content?
  after_save :poll_feed, if: :saved_change_to_feed_content?

  private

  def poll_feed
    result = EntryUtilities.get_new_and_updated(self.feed_url, self.feed_content)

    logger.debug result.to_s

    add_new_entries(result[:new])
    update_entries(result[:updated])
  end

  def add_new_entries(new_entries)
    new_entries.each do |entry|
      document = Document.create!(
          title: entry.title,
          description: entry.summary,
          author: entry.author,
          published_at: entry.published,
          url: entry.url,
          content: entry.content,
      )

      Entry.create!(
        document: document,
        channel: self,
      )
    end
  end

  def update_entries(updated_entries)
    updated_entries.each do |entry|
      document = Document.create!(
          title: entry.title,
          description: entry.summary,
          author: entry.author,
          published_at: entry.published,
          url: entry.url,
          content: entry.content,
      )

      Entry.create!(
        document: document,
        channel: self,
      )
    end
  end

  def update_feed_content
    headers = {}
    headers["If-Modified-Since"] = self.polled_at.httpdate if self.polled_at
    headers["If-None-Match"] = self.etag if self.etag

    response = HttpUtilities.get(self.feed_url, headers)
    return unless response

    self.polled_at = Time.current
    self.etag = response.headers[:Etag]

    return if response.status == 304
    self.feed_content = HttpUtilities.body_to_s(response)
  end

  def update_metadata
    feed = Feedjira.parse(self.feed_content) rescue nil
    return unless feed

    attributes = {}

    attributes[:title] = feed.title if feed.respond_to?(:title)
    attributes[:description] = feed.description if feed.respond_to?(:description)
    attributes[:url] = HttpUtilities.normalize(
      (feed.url if feed.respond_to?(:url)) || URI(self.feed_url).host
    )
    attributes[:icon] = HttpUtilities.get_icon(self.feed_url) if feed.respond_to?(:feed_url)
    attributes[:feed_url] = feed.feed_url if feed.respond_to?(:feed_url) && feed.feed_url

    update_columns(attributes) unless attributes.empty?
  end
end
