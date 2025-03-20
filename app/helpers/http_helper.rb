module HttpHelper
  extend self

  def get(url, headers = {}, follow = true)
    response = HTTPX.get(url, headers: headers)

    return nil if response.error

    if follow && response.status.between?(301, 302) && response.headers["location"].present?
      absolute_url = get_absolute_url(response.headers["location"], url)
      return get(absolute_url, headers, false)
    end

    response
  end

  def normalize_url(url)
    return nil unless url.is_a?(String) && !url.empty?

    url = "https://#{url}" unless is_absolute_url?(url)
    url = url.chomp("/")

    uri = URI.parse(url) rescue nil
    uri && uri.scheme =~ /\A(http|https)\z/ ? url : nil
  end

  def get_absolute_url(path, url)
    return path if is_absolute_url?(path)

    base_url = get_base_url(url)
    uri = URI.join(base_url, path)
    uri ? uri.to_s : nil
  end

  def is_absolute_url?(url)
    url.start_with?("http://", "https://")
  end

  def get_base_url(url)
    return nil unless url

    uri = URI.parse(url)

    if uri.port == uri.default_port
      "#{uri.scheme}://#{uri.host}"
    else
      "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end
  end

  def body_to_s(response)
    response.body.to_s.force_encoding("UTF-8")
  end

  def get_feed_url(url, discover = true)
    url = normalize_url(url)
    response = get(url)
    return nil unless response

    feed = FeedHelper.parse(body_to_s(response)) rescue nil
    return (feed.try(:feed_url) || url) if feed

    return nil unless discover

    html = body_to_s(response)
    path = extract_feed_url(html)
    return nil unless path

    feed_url = get_absolute_url(path, url)
    return nil unless feed_url

    get_feed_url(feed_url, false)
  end

  def extract_feed_url(html)
    doc = Nokogiri::HTML(html)

    path = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
           doc.at('link[type="application/rss+xml"]')&.[]("href")

    path
  end

  def get_icon(url)
    response = get(url)
    return unless response

    doc = Nokogiri::HTML(body_to_s(response))
    candidates = doc.css('link[rel~="icon"], link[rel~="apple-touch-icon"]').map { |link| link[:href] }.compact

    absolute_candidates = candidates.map { |href| get_absolute_url(href, url) }.compact

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

  def remove_protocol_and_host(url)
    parsed = URI(url)
    result = [ parsed.userinfo, parsed.path, parsed.query, parsed.fragment ].join
    result.empty? || result == "/" ? url : result
  end
end
