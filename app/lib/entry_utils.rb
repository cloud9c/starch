module EntryUtils
  extend self

  CACHE_DURATION = 7.days
  ENTRY_LIMIT = 300

  def get_stable_id(feed_url, entry_data)
    parts = []
    parts << feed_url

    if entry_data.id.present?
      parts << entry_data.id
    else
      if entry_data.url
        uri = URI(entry_data.url)
        result = [ uri.userinfo, uri.path, uri.query, uri.fragment ].compact.join
        result.empty? || result == "/" ? uri.to_s : result

        parts << entry_url.without_protocol_and_host
      end

      parts << entry_data.published.iso8601 if entry_data.published
      parts << entry_data.title if entry_data.title
    end

    Digest::SHA1.hexdigest(parts.compact.join)
  end

  def get_fingerprint(entry_data)
    Digest::MD5.hexdigest([
      entry_data.title,
      entry_data.content,
      entry_data.author
    ].compact.join)
  end

  def get_new_and_updated(feed_url, feed_content)
    feed = ChannelUtils.parse_feed(feed_content) rescue nil

    Rails.logger.error "Failed to parse feed content for URL: #{feed_url}" unless feed

    return { new: [], updated: [] } unless feed

    new_entries = []
    updated_entries = []

    # Process entries in reverse order so oldest come first
    feed.entries.first(ENTRY_LIMIT).reverse_each do |entry_data|
      stable_id = get_stable_id(feed_url, entry_data)
      fingerprint = get_fingerprint(entry_data)

      if is_new?(stable_id)
        new_entries << entry_data
        cache_entry(stable_id, fingerprint)
      elsif is_updated?(stable_id, fingerprint)
        updated_entries << entry_data
        update_entry_cache(stable_id, fingerprint)
      end
    end

    { new: new_entries, updated: updated_entries }
  end

  def format_text(html)
    return nil if html.nil? || html.empty?

    text = Nokogiri::HTML(html).xpath("//text()").map(&:text).join(" ")
    text.gsub(/\s+/, " ").strip
  end

  def format_description(html)
    text = EntryUtils.format_text(html)
    return nil if text.nil?

    text.strip.gsub(/\s+/, " ")[0...300]
  end

  require "image_size/uri"
  def extract_thumbnail(html, min_width: 100, min_height: 100)
    doc = Nokogiri::HTML(html)

    images = doc.css("img")

    images.each do |image|
      src = image["src"]

      begin
        size = ImageSize.url(src).size
      rescue
        next
      end

      next if size.nil?
      width, height = size
      return src if width >= min_width && height >= min_height
    end

    nil
  end

  def get_raw_entry_data(entry_data)
    url = UrlUtils.normalize(entry_data.url)
    content = SanitizeUtils.clean_html(entry_data.content || entry_data.summary, url)
    description = entry_data.summary if entry_data.summary && entry_data.content

    {
      source_type: :rss,
      title: self.format_text(entry_data.title),
      description: format_text(description),
      author: self.format_text(entry_data.author),
      published_at: entry_data.published || Time.current,
      url: url,
      content: content,
      thumbnail_url: entry_data.try(:media_thumbnail_url) || extract_thumbnail(content)
    }
  end

  def get_extracted_entry_data(url)
    parsed_data = ReadingParser.extract(url)
    return {} unless parsed_data

    content = SanitizeUtils.clean_html(parsed_data["content"], url)

    result = {
      content: content,
      thumbnail_url: extract_thumbnail(content),
      title: format_text(parsed_data["title"]),
      author: format_text(parsed_data["byline"]),
      published_at: (DateTime.parse(parsed_data["publishedTime"]) rescue nil)
    }

    result.compact
  end

  private

  def is_new?(stable_id)
    return false if Rails.cache.exist?("entry/stable_id/#{stable_id}")
    return false if Entry.exists?(stable_id: stable_id)
    true
  end

  def is_updated?(stable_id, new_fingerprint)
    return false if is_new?(stable_id)

    # Check cache first
    if Rails.cache.exist?("entry/stable_id/#{stable_id}")
      old_fingerprint = Rails.cache.read("entry/stable_id/#{stable_id}/fingerprint")
      return old_fingerprint != new_fingerprint
    end

    # Fallback to database
    entry = Entry.find_by(stable_id: stable_id)
    return false unless entry

    old_fingerprint = entry.fingerprint
    old_fingerprint != new_fingerprint
  end

  def cache_entry(stable_id, fingerprint)
    Rails.cache.write("entry/stable_id/#{stable_id}", true, expires_in: CACHE_DURATION)
    update_entry_cache(stable_id, fingerprint)
  end

  def update_entry_cache(stable_id, fingerprint)
    Rails.cache.write("entry/stable_id/#{stable_id}/fingerprint", fingerprint, expires_in: CACHE_DURATION)
  end
end
