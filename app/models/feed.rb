class Feed < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :documents, through: :entries, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :feed_url, presence: true, uniqueness: true

  after_create :schedule_initial_update

  def self.parse_feed(content)
    Feedjira.parse(content) rescue nil
  end

  def update_content
    headers = {}
    headers["If-Modified-Since"] = polled_at.httpdate if polled_at.present?
    headers["If-None-Match"] = etag if etag.present?

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(feed_url, headers: headers)
    response.raise_for_status

    update(polled_at: Time.current, etag: response.headers[:Etag])

    return false if response.status == 304

    response_body = response.body.to_s

    update(content: response_body)

    true
  end

  def update_metadata
    feed = Feed.parse_feed(content) rescue nil
    return unless feed

    feed_url = UrlUtils.normalize(feed.try(:feed_url)) || feed_url
    site_url = UrlUtils.normalize(feed.try(:url)) || UrlUtils.get_origin(feed_url)

    attributes = {
      title: FormatUtils.format_text(feed.try(:title)),
      description: FormatUtils.format_text(feed.try(:description)),
      feed_url: feed_url,
      url: site_url,
      icon: FormatUtils.find_icon(site_url)
    }.compact

    update(attributes) unless attributes.empty?
  end

  def poll
    feed_content = Feed.parse_feed(content) rescue nil
    return unless feed_content

    result = Entry.get_new_and_updated(feed_url, feed_content)

    result[:new].each do |entry_data|
      Entry.create_from_feed(entry_data, self)
    end

    result[:updated].each do |entry_data|
      Entry.update_from_feed(entry_data, feed_url)
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
end
