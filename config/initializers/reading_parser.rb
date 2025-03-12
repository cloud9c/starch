module ReadingParser
  def self.extract(url)
    service_uri = "http://#{Rails.env.production? ? 'starch-reading_parser' : 'localhost'}:3001/parse"
    headers = { "Content-Type" => "application/json" }

    response = HTTPX.post(service_uri, json: { url: url }, headers: headers)
    Rails.logger.debug "url: #{url}"

    case (response)
    in {status: 200}
      JSON.parse(response.body.to_s)
    in {status: 204}
      Rails.logger.debug "No content available for url: #{url}"
      nil
    in {status: 400..}
      Rails.logger.error "ReadingParser error: HTTP error #{response.status}"
      nil
    in {error: error}
      Rails.logger.error "ReadingParser error: Unexpected status code #{error.class}"
      nil
    end
  end
end
