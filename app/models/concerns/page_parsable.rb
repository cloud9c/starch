module PageParsable
  extend ActiveSupport::Concern

  def self.robots
    @robots ||= Robots.new "StarchBot"
  end

  def normalize_url(url)
    url.chomp("/")
  end

  def get_origin(domain)
    "https://" + get_host(domain)
  end

  def get_host(domain)
    "www.#{domain}"
  end

  def robot_allowed?(url)
    PageParsable.robots.allowed?(url)
  end

  def get_sitemap_from_robots(origin)
    response = HTTPX.get("#{origin}/robots.txt")
    return [] unless response.status == 200

    sitemaps = response.body.to_s.scan(/^Sitemap: (.+)$/i).flatten
    return [] if sitemaps.empty?

    sitemaps.flat_map { |url| parse_sitemap(url) }.compact
  end

  def get_sitemap(origin)
    robots_urls = get_sitemap_from_robots(origin)
    return robots_urls unless robots_urls.empty?
    parse_sitemap("#{origin}/sitemap.xml")
  end

  def parse_sitemap(sitemap_url)
    sitemap = SitemapParser.new(sitemap_url, { recurse: true })
    sitemap.to_a.map { |url| normalize_url(url) }
  rescue RuntimeError => e
    []
  end

  def get_absolute_url(url, base)
    uri = URI.join(base, url) rescue nil
    normalize_url uri.to_s
  end

  def get_icon(candidates, host)
    image_url = candidates.find { |url| is_valid_image?(get_absolute_url(url, host)) }
    get_absolute_url(image_url, host)
  end

  def is_valid_image?(url)
    return false unless url
    response = HTTPX.get(url)
    return false if response.is_a?(HTTPX::ErrorResponse)

    response.headers["content-type"]&.start_with?("image/")
  rescue HTTPX::Error
    false
  end

  def get_description(doc)
    description = doc.at('meta[name="description"]')&.[]("content")&.strip
    description || get_content(doc, 150)
  end

  def get_title(doc)
    doc.at("title")&.text&.strip
  end

  def get_content(doc, limit = 100000)
    doc.css("script, style").each(&:remove)
    doc.text.strip.gsub(/\s+/, " ")[0..limit]
  end

  def get_feed(doc)
    doc.at('link[type="application/rss+xml"]')&.[]("href") ||
    doc.at('link[type="application/atom+xml"]')&.[]("href")
  end
end
