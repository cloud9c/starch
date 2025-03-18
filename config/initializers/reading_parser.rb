module ReadingParser
  extend self

  def extract(url)
    service_uri = "http://#{Rails.env.production? ? 'starch-reading_parser' : 'localhost'}:3001/parse"
    headers = { "Content-Type" => "application/json" }
    response = HTTPX.post(service_uri, json: { url: url }, headers: headers)

    Rails.logger.debug "No content available for url: #{url}" if response.status == 204
    return nil if response.status == 204

    if response.error
      Rails.logger.error "ReadingParser error: Unexpected status code #{response.error}"
      return nil
    end

    return nil if response.status != 200

    article = JSON.parse(response.body.to_s)
    article
  end
end
