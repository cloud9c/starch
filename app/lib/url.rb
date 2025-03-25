class Url
  attr_reader :uri

  def initialize(url, normalize = true)
    return nil if url.blank?

    if !normalize
      @uri = URI.parse(url)
      return
    end

    url = "https://#{url}" unless url.to_s.start_with?("http://", "https://")
    url = url.chomp("/")

    @uri = URI.parse(url) rescue nil

    # Validate the URI
    if !@uri || !(@uri.scheme =~ /\A(http|https)\z/)
      @uri = nil
    end
  end

  def to_s
    @uri.to_s
  end

  def to_absolute(path)
    return path if Url.is_absolute?(path)

    uri = URI.join(self.origin, path) rescue nil
    uri ? uri.to_s : nil
  end

  def is_absolute?
    @uri && @uri.scheme =~ /\A(http|https)\z/
  end

  def origin
    return nil unless @uri

    if @uri.port == @uri.default_port
      "#{@uri.scheme}://#{@uri.host}"
    else
      "#{@uri.scheme}://#{@uri.host}:#{@uri.port}"
    end
  end

  def remove_protocol_and_host
    return nil unless @uri

    result = [ @uri.userinfo, @uri.path, @uri.query, @uri.fragment ].compact.join
    result.empty? || result == "/" ? @uri.to_s : result
  end

  def self.normalize(url)
    instance = new(url)
    instance.uri ? instance.to_s : nil
  end

  def self.is_absolute?(path)
    Url.new(path, false).is_absolute?
  end
end
