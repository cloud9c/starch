class Channel < ApplicationRecord
  has_many :documents
  has_many :subscriptions
  has_many :users, through: :subscriptions
  has_many :documents

  validates :feed_url, presence: true, uniqueness: true
  before_create :get_metadata
  after_create :perform_jobs

  private

  def get_metadata
    feed = FeedParser.get_feed(self.feed_url)

    self.title = feed.title
    self.description = feed.description

    self.icon = get_icon(self.feed_url)
  end

  def perform_jobs
    UpdateFeedJob.perform_later(self)
  end

  def get_icon(feed_url)
    host = WebUrl.normalize(URI(feed_url).host)

    response = FeedParser.get(host)
    doc = Nokogiri::HTML(response.body.to_s)

    candidates = [
      doc.at_css('link[rel~="icon"]')&.[]("href"),
      "/favicon.ico"
    ].compact

    image_url = candidates.find { |url| is_valid_image?(WebUrl.get_absolute(url, host)) }
    WebUrl.get_absolute(image_url, host)
  end

  def is_valid_image?(url)
    logger.debug "IS VALID IMAGE #{url}"

    return false unless url
    response = FeedParser.get(url)
    return false if response.is_a?(HTTPX::ErrorResponse)

    response.headers["content-type"]&.start_with?("image/")
  rescue HTTPX::Error
    false
  end
end
