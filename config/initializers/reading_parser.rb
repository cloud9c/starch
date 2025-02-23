module ReadingParser
  def self.parse(html)
    uri = "http://#{Rails.env.production? ? 'starch-reading_parser' : 'localhost'}:3001/parse"
    headers = { "Content-Type" => "application/json" }

    begin
      Rails.logger.debug "ReadingParser debug: sending html size: #{html.bytesize} bytes (#{(html.bytesize / 1024.0).round(2)} KB)"

      response = HTTPX.post(uri, json: { html: html }, headers: headers)

      case response.status
      when 200
        JSON.parse(response.body.to_s)
      when 204
        nil
      when 400..599
        Rails.logger.error "ReadingParser error: Received non-2xx status code #{response.status}"
        nil
      else
        Rails.logger.error "ReadingParser error: Unexpected status code #{response.status}"
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
