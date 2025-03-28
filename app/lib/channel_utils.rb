module ChannelUtils
  extend self

  def parse_feed(content)
    Feedjira.parse(content)
  end

  def body_to_s(response)
    response.body.to_s.force_encoding("UTF-8")
  end

  def get_feed_url(url, discover = true)
    normalized_url = UrlUtils.normalize(url)

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(normalized_url)
    return nil if response.error

    feed = self.parse_feed(body_to_s(response)) rescue nil
    return (feed.try(:feed_url) || normalized_url) if feed

    if discover
      html = body_to_s(response)
      path = extract_feed_url(html)
      return nil unless path

      feed_url = URI.join(normalized_url, path).to_s
      return get_feed_url(feed_url, false)
    end
  end

  def extract_feed_url(html)
    doc = Nokogiri::HTML(html)

    path = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
           doc.at('link[type="application/rss+xml"]')&.[]("href")

    path
  end

  def get_icon(url)
    origin = UrlUtils.get_origin(UrlUtils.normalize(url))

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(origin)
    return unless response

    doc = Nokogiri::HTML(body_to_s(response))
    candidates = doc.css('link[rel~="icon"], link[rel~="apple-touch-icon"]').map { |link| link[:href] }.compact

    absolute_candidates = candidates.map do |href|
      URI.join(origin, href).to_s
    end.compact

    ranked_images = absolute_candidates.first(5).map do |abs_url|
      size = FastImage.size(abs_url)
      [ abs_url, size ] if size
    end.compact

    ranked_by_area = ranked_images.map do |abs_url, size|
      [ abs_url, size[0] * size[1] ]
    end

    largest_image = ranked_by_area.sort_by { |_, area| -area }.first
    largest_image ? largest_image[0] : nil
  end
end
