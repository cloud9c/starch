module UrlUtils
  extend self

  def get(url, follow = true)
    response = HTTPX.get(url)

    return nil if response.error

    if follow && (response.status == 301 || response.status == 302) && response.headers["location"]
      return get(get_absolute(response.headers["location"], url), false)
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

  def get_feed_url(url)
    url = UrlUtils.normalize(url)

    # 1. Try url directly
    response = UrlUtils.get(url)
    return unless response

    # assuming all feeds are application/xml
    return response.uri.to_s if response.headers["content-type"].include?("application/xml")

    # 2. Try to find it myself
    doc = Nokogiri::HTML(response.body.to_s)

    link = doc.at('link[type="application/atom+xml"]')&.[]("href") ||
           doc.at('link[type="application/rss+xml"]')&.[]("href")

    UrlUtils.get_absolute(link, response.uri.host)
  end
end
