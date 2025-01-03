class Channel < ApplicationRecord
  has_many :documents
  has_many :subscriptions
  has_many :users, through: :subscriptions

  validates :feed_url, presence: true, uniqueness: true
  after_validation :update_feed_content

  before_save :update_metadata, if: :will_save_change_to_feed_content?
  before_save :push_new_documents_to_users, if: :will_save_change_to_feed_content?

  def push_documents_to_new_users(user_id)
    feed = Feedjira.parse(self.feed_content) rescue nil
    return nil unless feed

    latest_entries = feed.entries.sort_by(&:published).reverse.first(5)
    create_documents_for_entries(latest_entries, [ user_id ])
  end

  private

  def update_feed_content
    headers = {}
    headers["If-Modified-Since"] = self.polled_at.httpdate if self.polled_at
    headers["If-None-Match"] = self.etag if self.etag

    response = FeedUtilities.get(self.feed_url, headers)
    return unless response

    self.polled_at = Time.current
    self.etag = response.headers[:Etag]

    return if response.status == 304
    self.feed_content = FeedUtilities.body_to_s(response)

    puts "Time: #{self.polled_at}"
    puts "ETag: #{self.etag}"
  end

  def update_metadata
    feed = Feedjira.parse(self.feed_content) rescue nil
    return unless feed

    self.title = feed.title if feed.respond_to?(:title)
    self.description = feed.description if feed.respond_to?(:description)
    self.url = FeedUtilities.normalize(
            (feed.url if feed.respond_to?(:url)) || URI(self.feed_url).host
          )
    self.icon = FeedUtilities.get_icon(self.feed_url) if feed.respond_to?(:feed_url)

    self.feed_url = feed.feed_url if feed.respond_to?(:feed_url) && feed.feed_url
  end

  def create_documents_for_entries(entries, user_ids)
    entries.each do |entry|
      user_ids.each do |user_id|
        documents.create!(
          title: entry.title,
          description: entry.summary,
          author: entry.author,
          published_at: entry.published,
          url: entry.url,
          content: entry.content,
          user_id: user_id
        )
      end
    end
  end

  def push_new_documents_to_users
    feed = Feedjira.parse(self.feed_content) rescue nil
    return nil unless feed

    ActiveRecord::Base.transaction do
      new_entries = feed.entries.select do |entry|
        entry.published > self.polled_at || 0
      end

      return if new_entries.empty?

      create_documents_for_entries(new_entries, users.pluck(:user_id))
    end
  end
end
