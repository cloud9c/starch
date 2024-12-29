module FeedParser
  extend self

  def get(url, follow = true)
    response = HTTPX.get(url)
    if follow && (response.status == 301 || response.status == 302) && response.headers["location"]
      return get(WebUrl.get_absolute(response.headers["location"], url), false)
    end
    response
  end

  def get_feed(url)
    xml = get(url).body.to_s
    Feedjira.parse(xml) rescue nil
  end

  def get_feed_url(url)
    url = WebUrl.normalize(url)

    return nil unless WebUrl.valid?(url)

    # 1. Try url directly
    response = get(url)
    return response.uri.to_s if response.headers["content-type"].include?("application/xml")

    # 2. Try to find it myself.
    doc = Nokogiri::HTML(response.body.to_s)

    link = doc.at('link[type="application/rss+xml"]')&.[]("href") ||
           doc.at('link[type="application/atom+xml"]')&.[]("href")

    WebUrl.get_absolute(link, response.uri.host)
  end
end
