module ReadingParser
  def self.parse(html)
    uri = "http://#{Rails.env.production? ? 'starch-reading_parser' : 'localhost'}:3001/parse"
    headers = { 'Content-Type' => 'application/json' }
    body = { html: html }.to_json

    begin
      response = HTTPX.post(uri, json: { html: html })

      if response.status >= 200 && response.status < 300
        JSON.parse(response.body.to_s)
      else
        Rails.logger.error "ReadingParser error: Received non-2xx status code #{response.status}"
        nil
      end
    rescue HTTPX::Error => e
      Rails.logger.error "ReadingParser error: #{e.message}"
      nil
    rescue JSON::ParserError => e
      Rails.logger.error "ReadingParser error: Failed to parse JSON response: #{e.message}"
      nil
    end
  end
end
