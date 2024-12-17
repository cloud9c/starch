class Channel < ApplicationRecord
  validates :domain, presence: true, uniqueness: true
  validate :validate_domain
  after_validation :fetch_metadata
  has_many :pages, dependent: :destroy
  has_many :feeds, dependent: :destroy

  private

  def validate_domain
    return if domain.blank?

    begin
      parsed_domain = PublicSuffix.parse(domain)

      unless PublicSuffix.valid?(domain)
        errors.add(:domain, "invalid domain")
      end
    rescue PublicSuffix::Error => e
      errors.add(:domain, "domain parsing error: #{e.message}")
    end
  end

  def fetch_metadata
    response = HTTPX.get("https://www.#{self.domain}")
    return unless response&.status == 200

    doc = Nokogiri::HTML(response.body.to_s)

    self.title = doc.at_css("title")&.text&.strip
    self.description = doc.at_css('meta[name="description"]')&.[]("content")&.strip
    self.image = find_favicon(doc)
  end

  def find_favicon(doc)
    candidates = [
      doc.at_css('link[rel="icon"]')&.[]("href"),
      doc.at_css('link[rel="shortcut icon"]')&.[]("href"),
      doc.at_css('link[rel="apple-touch-icon"]')&.[]("href"),
      "/favicon.ico",
      doc.at_css('meta[property="og:image"]')&.[]("content"),
      doc.at_css('meta[name="twitter:image"]')&.[]("content")
    ].compact
    image_url = candidates.find { |url| valid_image_url?(ensure_absolute_url(url)) }
    ensure_absolute_url(image_url)
  end

  def valid_image_url?(url)
    return false unless url
    response = HTTPX.get(url)
    return false if response.is_a?(HTTPX::ErrorResponse)

    response.headers["content-type"]&.start_with?("image/")
    rescue HTTPX::Error
      false
  end

  def ensure_absolute_url(url)
    return nil unless url
    begin
      uri = URI.parse(url)
      return url if uri.absolute?
      base = "https://#{self.domain}"
      base = base.chomp("/")
      url = url.start_with?("/") ? url : "/#{url}"
      "#{base}#{url}"
    rescue URI::Error
      nil
    end
  end
end
