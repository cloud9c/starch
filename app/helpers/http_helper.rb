module HttpHelper
  extend self

  def get(url, headers = {}, follow = true)
    Rails.logger.debug "getting #{url}"
    response = HTTPX.get(url, headers: headers)

    return nil if response.error

    if follow && (response.status == 301 || response.status == 302) && response.headers["location"]
      return get(get_absolute_url(response.headers["location"], url), headers: {}, follow: false)
    end

    response
  rescue
    nil
  end

  def normalize_url(url)
    return nil unless url.present?

    # Only allow http and https protocols
    if url.start_with?("http://", "https://")
      # URL already has a valid protocol
    elsif url.include?(":")
      # URL has a protocol but it's not http/https, reject it
      return nil
    else
      # Add https protocol
      url = "https://#{url}"
    end

    # Remove trailing slash
    url = url.chomp("/")

    # Validate it's a proper URL structure
    begin
      uri = URI.parse(url)
      return url if uri.host.present?
      nil
    rescue URI::InvalidURIError
      nil
    end
  end

  def get_absolute_url(url, host)
    origin = normalize_url(host)
    uri = URI.join(origin, url) rescue nil

    return nil unless uri

    uri.to_s
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

  def get_feed_url(url)
    url = normalize_url(url)
    response = get(url)
    return unless response

    feed = FeedHelper.parse(body_to_s(response)) rescue nil

    unless feed
      doc = Nokogiri::HTML(body_to_s(response))
      link = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
             doc.at('link[type="application/rss+xml"]')&.[]("href")
      url = get_absolute_url(link, response.uri.host)
      return unless url
      response = get(url)
      return unless response
      feed = FeedHelper.parse(body_to_s(response)) rescue nil
    end

    feed&.respond_to?(:feed_url) && feed&.feed_url ? feed.feed_url : url
  end

  def get_icon(url)
    host = normalize_url(URI(url).host)
    response = get(host)
    return unless response
    
    doc = Nokogiri::HTML(body_to_s(response))
    candidates = doc.css('link[rel~="icon"], link[rel~="apple-touch-icon"]').map { |link| link[:href] }.compact
    
    absolute_candidates = candidates.map { |href| get_absolute_url(href, host) }.compact
    
    ranked_images = absolute_candidates.map do |abs_url|
      size = FastImage.size(abs_url)
      [abs_url, size] if size
    end.compact
    
    ranked_by_area = ranked_images.map do |abs_url, size|
      [abs_url, size[0] * size[1]]
    end
    
    largest_image = ranked_by_area.sort_by { |_, area| -area }.first
    
    largest_image ? largest_image[0] : nil
  end

  def remove_protocol_and_host(url)
    parsed = URI(url)
    result = [ parsed.userinfo, parsed.path, parsed.query, parsed.fragment ].join
    if result == "" || result == "/"
      url
    else
      result
    end
  rescue
    if url.respond_to?(:gsub!)
      url.gsub!("http:", "")
      url.gsub!("https:", "")
    end
    url
  end
end
