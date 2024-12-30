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
    url = url.strip.downcase
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

  def get_feed_url(url)
    url = UrlUtils.normalize(url)

    # 1. Try url directly
    response = UrlUtils.get(url)
    return unless response

    # assuming all feeds are application/xml
    return response.uri.to_s if response.headers["content-type"].include?("application/xml")

    # 2. Try to find it myself
    doc = Nokogiri::HTML(body_to_s(response))

    link = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
           doc.at('link[type="application/rss+xml"]')&.[]("href")

    UrlUtils.get_absolute(link, response.uri.host)
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
