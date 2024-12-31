module UrlUtils
  extend self

  def get(url, headers = {}, follow = true)
    response = HTTPX.get(url, headers: headers)

    return nil if response.error

    if follow && (response.status == 301 || response.status == 302) && response.headers["location"]
      return get(get_absolute(response.headers["location"], url), headers: {}, follow: false)
    end

    response
  rescue
    nil
  end

  def normalize(url)
    url = "https://#{url}" unless url.start_with?("http://", "https://")
    url.chomp("/")
  end

  def get_absolute(url, host)
    origin = normalize(host)
    uri = URI.join(origin, url) rescue nil

    return nil unless uri

    uri.to_s
  end

  def body_to_s(response)
    response.body.to_s.force_encoding("UTF-8")
  end

  def get_canonical_feed_url(url)
    feed_url = get_feed_url(url)

    puts "FEED_URL: #{feed_url}"

    url = normalize(feed_url)
    response = get(url)
    return feed_url unless response

    puts "response: true"

    feed = Feedjira.parse(body_to_s(response)) rescue nil
    return feed_url unless feed

    puts "feed: true"

    if feed.respond_to?(:feed_url)
      puts "NEW_FEED_URL: #{feed.feed_url}"
      return feed.feed_url
    end

    feed_url
  end

  def get_feed_url(url)
    url = normalize(url)

    # 1. Try url directly
    response = get(url)
    return unless response

    # assuming all feeds are application/xml
    return response.uri.to_s if response.headers["content-type"].include?("application/xml")

    # 2. Try to find it myself
    doc = Nokogiri::HTML(body_to_s(response))

    link = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
           doc.at('link[type="application/rss+xml"]')&.[]("href")

    get_absolute(link, response.uri.host)
  end

  def get_icon(url)
    host = normalize(URI(url).host)
    favicon_url = get_absolute("/favicon.ico", host)

    return favicon_url if is_valid_image?(favicon_url)

    response = get(host)
    return unless response

    doc = Nokogiri::HTML(body_to_s(response))

    candidates = doc.css('link[rel~="icon"]').map { |link| link[:href] }.compact
    href = candidates.find { |href| is_valid_image?(get_absolute(href, host)) }

    get_absolute(href, host) if href
  end

  def is_valid_image?(url)
    response = get(url)

    return false unless response
    return false if response.body.empty?

    response.headers["content-type"]&.start_with?("image/")
  end
end
