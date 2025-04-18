module ReadingParser
  extend self

  def extract(url)
    service_uri = "http://starch-reading-parser:3001/parse"
    headers = { "Content-Type" => "application/json" }
    response = HTTPX.post(service_uri, json: { url: url }, headers: headers)

    return nil if response.error
    return nil if response.status != 200

    article = JSON.parse(response.body.to_s)
    article["content"] = SanitizeUtils.sanitize_html(article["content"], url)
    article
  end
end
