class Channel < ApplicationRecord
  has_many :documents
  has_many :subscriptions
  has_many :users, through: :subscriptions

  before_validation :get_canonical_feed_url
  validates :feed_url, presence: true, uniqueness: true

  before_save :get_feed_content, if: :will_save_change_to_feed_url? 
  before_save :subscribe_to_hub, if: :will_save_change_to_hub_url?

  before_save :update_metadata

  private

  def get_canonical_feed_url
    url = UrlUtils.normalize(self.feed_url)
    response = UrlUtils.get(url)
    return unless response

    feed = Feedjira.parse(response.body.to_s) rescue nil
    return unless feed

    self.feed_url = feed.feed_url if feed.feed_url
  end

  def get_feed_content
    response = UrlUtils.get(self.feed_url)
    return unless response
    self.feed_content = response.body.to_s
  end

  def update_metadata
    feed = Feedjira.parse(self.feed_content) rescue nil
    return unless feed

    self.title = feed.title
    self.description = feed.description
    self.url = UrlUtils.normalize(
            feed.url || URI(self.feed_url).host
          )
    self.icon = get_icon(self.feed_url)

    if feed.feed_url
      self.feed_url = feed.feed_url
    end

    if feed.respond_to?(:hubs) && feed.hubs.any?
      self.hub_url = feed.hubs.first
    end
  end

  def update_entries
    # feed.entries.each do |entry|
    #   puts "title: #{entry.title}"
    #   puts "published: #{entry.published}"
    #   puts "url: #{entry.url}"
    #   puts "id: #{entry.entry_id}"
    #   puts "summary: #{entry.summary}"
    #   puts "author: #{entry.author}"
    # end
  end

  def get_icon(url)
    host = UrlUtils.normalize(URI(url).host)
    favicon_url = UrlUtils.get_absolute("/favicon.ico", host)

    return favicon_url if is_valid_image?(favicon_url)

    response = UrlUtils.get(host)
    return unless response

    doc = Nokogiri::HTML(response.body.to_s)

    candidates = doc.css('link[rel~="icon"]').map { |link| link[:href] }.compact
    href = candidates.find { |href| is_valid_image?(UrlUtils.get_absolute(href, host)) }

    UrlUtils.get_absolute(href, host) if href
  end

  def is_valid_image?(url)
    response = UrlUtils.get(url)

    return false unless response
    return false if response.body.empty?

    response.headers["content-type"]&.start_with?("image/")
  end

  def subscribe_to_hub
    return unless self.hub_url.present?
    
    hub_secret = SecureRandom.hex(32)

    self.hub_secret = hub_secret
    
    HTTPX.post(self.hub_url, form: {
      'hub.mode' => 'subscribe',
      'hub.topic' => self.feed_url,
      'hub.callback' => "#{Rails.application.config.host}/websub/verify",
      'hub.secret' => hub_secret
    })
  end
end
