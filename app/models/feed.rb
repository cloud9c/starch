class Feed < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :documents, through: :entries, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :feed_url, presence: true, uniqueness: true
  after_create :schedule_initial_update

  def parsed_feed
    @parsed_feed ||= (Feedjira.parse(content) rescue nil)
  end

  def poll
    headers = {}
    headers["If-Modified-Since"] = polled_at.httpdate if polled_at.present?
    headers["If-None-Match"] = etag if etag.present?

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(feed_url, headers: headers)
    response.raise_for_status

    update(polled_at: Time.current, etag: response.headers[:Etag])

    return false if response.status == 304

    response_body = response.body.to_s.force_encoding("utf-8")
    update(content: response_body)

    update_metadata
    create_new_entries
    update(initial_poll_complete: true)

    true
  end

  private
    def schedule_initial_update
      UpdateFeedJob.perform_later(id)
    end

    def update_metadata
      return unless parsed_feed

      feed_url = UrlUtils.normalize(parsed_feed.try(:feed_url)) || feed_url
      site_url = UrlUtils.normalize(parsed_feed.try(:url)) || UrlUtils.get_origin(feed_url)

      attributes = {
        title: FormatUtils.format_text(parsed_feed.try(:title)),
        description: FormatUtils.format_text(parsed_feed.try(:description)),
        feed_url: feed_url,
        url: site_url,
        icon: FormatUtils.find_icon(site_url)
      }.compact

      update(attributes)
    end

    def create_new_entries
      return unless parsed_feed

      new_entries = Entry.get_new_entries(feed_url, parsed_feed)
      new_entries.each do |parsed_entry|
        entries.create(parsed_entry: parsed_entry)
      end
    end
end
