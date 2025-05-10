module ChannelUtils
  extend self

  def parse_feed(content)
    Feedjira.parse(content) rescue nil
  end

  def find_feed_url(url)
    normalized_url = UrlUtils.normalize(url)
    return nil if normalized_url.nil?

    attempts = [
      normalized_url,
      UrlUtils.get_origin(normalized_url)
    ]

    attempts.compact.each do |attempt_url|
      feed_url = get_feed_url(attempt_url)
      return feed_url if feed_url
    end

    nil
  end

  def get_feed_url(url, should_extract = true)
    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(url)
    return nil if response.error

    mime_type = response.headers["content-type"]
    body = response.body.to_s.force_encoding("UTF-8")

    if should_extract && mime_type.include?("text/html")
      extracted_feed_url = extract_feed_url(body, url)
      return nil unless extracted_feed_url

      return get_feed_url(extract_feed_url(body, url), false)
    end

    feed = parse_feed(body)
    (feed.try(:feed_url) || url) if feed
  end

  def extract_feed_url(html, url)
    return nil unless html.is_a?(String)

    doc = Nokogiri::HTML(html)
    path = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
          doc.at('link[type="application/rss+xml"]')&.[]("href")

    return nil unless path

    origin = UrlUtils.get_origin(url)

    URI.join(origin, path).to_s
  end

  def get_icon(base_url)
    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(base_url)
    return nil if response.error

    body = response.body.to_s.force_encoding("UTF-8")

    doc = Nokogiri::HTML(body)
    icon_url = doc.css('link[rel~="apple-touch-icon"], link[rel~="icon"]').map { |link| link[:href] }.first
    icon_url ||= "/favicon.ico"

    URI.join(base_url, icon_url).to_s rescue nil
  end
end
