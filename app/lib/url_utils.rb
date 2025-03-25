module UrlUtils
  extend self

  def normalize(url)
    raise ArgumentError, "URL cannot be blank" if url.blank?

    url = "https://#{url}" unless url.to_s.start_with?("http://", "https://")
    url = url.chomp("/")
    @uri = URI.parse(url)
  end

  def get_origin(url)
    uri = URI(url)
    "#{uri.scheme}://#{uri.host}#{uri.port == uri.default_port ? '' : ':' + uri.port.to_s}"
  end
end
