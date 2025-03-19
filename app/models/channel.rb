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

  def update_metadata
    feed = FeedHelper.parse(self.feed_content) rescue nil
    return unless feed

    feed_url = HttpHelper.normalize_url(feed.try(:feed_url)) || self.feed_url
    url = HttpHelper.normalize_url(
      feed.try(:url) || HttpHelper.get_base_url(feed_url)
    )

    attributes = {
      title: EntryHelper.format_text(feed.try(:title)),
      description: EntryHelper.format_text(feed.try(:description)),
      feed_url: feed_url,
      url: url,
      icon: HttpHelper.get_icon(url)
    }.compact

    update(attributes) unless attributes.empty?
  end

  private

  def schedule_initial_update
    UpdateChannelJob.perform_now(id, true)
  end
end
