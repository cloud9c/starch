module ChannelUtils
  extend self

  def parse_feed(content)
    Feedjira.parse(content)
  end

  def body_to_s(response)
    response.body.to_s.force_encoding("UTF-8")
  end

  def find_feed_url(url)
    normalized_url = UrlUtils.normalize(url)
    attempts = [
      normalized_url, 
      extract_feed_url(normalized_url), 
      UrlUtils.get_origin(normalized_url)
    ]
    
    attempts.compact.each do |attempt_url|
      feed_url = get_feed_url(attempt_url)
      return feed_url if feed_url
    end
    
    nil
  end

  def get_feed_url(url)
    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(url)
    return nil if response.error

    feed = self.parse_feed(body_to_s(response)) rescue nil
    return (feed.try(:feed_url) || url) if feed
    
    nil
  end

  def extract_feed_url(html)
    return nil unless html.is_a?(String)
    
    begin
      doc = Nokogiri::HTML(html)
      path = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
            doc.at('link[type="application/rss+xml"]')&.[]("href")
      path
    rescue
      nil
    end
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
