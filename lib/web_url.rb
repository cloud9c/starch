module WebUrl
  class InvalidWebUrlError < StandardError; end

  SUPPORTED_SCHEMES = ["http", "https"]

  extend self

  def parse(value)
    if value.blank?
      raise InvalidWebUrlError, "can't be blank"
    end

    uri = URI.parse(value)

    unless SUPPORTED_SCHEMES.include?(uri.scheme)
      raise InvalidWebUrlError, "invalid scheme '#{uri.scheme}'"
    end

    if uri.host.blank?
      raise InvalidWebUrlError, "host is blank"
    end

    uri
  rescue URI::InvalidURIError => err
    raise InvalidWebUrlError, err.message
  end

  def normalize(url)
    url = url.strip.downcase
    url = "https://#{url}" unless url.start_with?('http://', 'https://')

    url.chomp("/")
  end

  def get_absolute(url, host)
    origin = normalize(host)
    uri = URI.join(origin, url) rescue nil

    return nil unless uri

    uri.to_s
  end

  def valid?(value)
    parse(value)
    true
  rescue InvalidWebUrlError
    false
  end
end
