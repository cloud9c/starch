module ChannelUtils
  extend self

  def parse_feed(content)
    Feedjira.parse(content)
  end

  def body_to_s(response)
    response.body.to_s.force_encoding("UTF-8")
  end

  def get_feed_url(url, discover = true)
    url_instance = Url.new(url)

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(url_instance.to_s, headers: headers)
    return nil if response.error

    feed = self.parse_feed(body_to_s(response)) rescue nil
    return (feed.try(:feed_url) || url_instance.to_s) if feed

    if discover
      html = body_to_s(response)
      path = extract_feed_url(html)
      return nil unless path

      feed_url = url_instance.with_path(path)
      return nil unless feed_url

      get_feed_url(feed_url, false)
    end
  end

  def extract_feed_url(html)
    doc = Nokogiri::HTML(html)

    path = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
           doc.at('link[type="application/rss+xml"]')&.[]("href")

    path
  end

  def get_icon(url)
    origin = Url.new(url).origin

    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(origin, headers: headers)
    return unless response

    doc = Nokogiri::HTML(body_to_s(response))
    candidates = doc.css('link[rel~="icon"], link[rel~="apple-touch-icon"]').map { |link| link[:href] }.compact

    absolute_candidates = candidates.map do |href|
      origin.with_path(href)
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
