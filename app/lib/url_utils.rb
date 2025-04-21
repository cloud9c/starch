module UrlUtils
  extend self

  def normalize(url)
    raise ArgumentError, "URL cannot be blank" if url.blank?

    url = "https://#{url}" unless url.start_with?("http://", "https://")
    uri = URI.parse(url)

    unless uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)
      raise ArgumentError, "Invalid URL format"
    end

    url
  end

  def get_origin(url)
    uri = URI(normalize(url))
    "#{uri.scheme}://#{uri.host}#{uri.port == uri.default_port ? '' : ':' + uri.port.to_s}"
  end
end
