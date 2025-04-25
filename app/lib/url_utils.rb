module UrlUtils
  extend self

  def normalize(url)
    return nil if url.nil?

    url = "https://#{url}" unless url.start_with?("http://", "https://")
    begin
      uri = URI.parse(url)
    rescue
      return nil
    end

    return nil unless uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)

    url
  end

  def get_origin(url)
    normalized_url = normalize(url)
    return nil if normalized_url.nil?

    uri = URI(normalized_url)
    "#{uri.scheme}://#{uri.host}#{uri.port == uri.default_port ? '' : ':' + uri.port.to_s}"
  end
end
