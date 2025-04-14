module ReadingParser
  extend self

  def extract(url)
    service_uri = "http://starch-reading-parser:3001/parse"
    headers = { "Content-Type" => "application/json" }
    response = HTTPX.post(service_uri, json: { url: url }, headers: headers)

    if response.error
      Rails.logger.error "ReadingParser error: Unexpected error #{response.error}"
      return nil
    end

    Rails.logger.debug "No content available for url: #{url}" if response.status == 204
    return nil if response.status != 200

    article = JSON.parse(response.body.to_s)
    article
  end
end
