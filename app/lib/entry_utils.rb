module EntryUtils
  extend self

  mattr_reader :cache_duration, default: 7.days

  def get_stable_id(feed_url, entry_data)
    parts = []
    parts << feed_url

    if entry_data.id.present?
      parts << entry_data.id
    else
      if entry_data.url
        entry_url = Url.new(entry_data.url)
        parts << entry_url.remove_protocol_and_host
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

    feed.entries.each do |entry_data|
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

  def extract_thumbnail(html, min_width: 100, min_height: 100)
    doc = Nokogiri::HTML(html)

    images = doc.css("img")

    images.each do |img|
      src = img["src"]
      next if src.nil? || src.empty?

      if src.start_with?("//")
        src = "https:#{src}"
      elsif src.start_with?("/")
        next
      end

      begin
        dimensions = FastImage.size(src)

        next if dimensions.nil?

        width, height = dimensions

        if width >= min_width && height >= min_height
          return src
        end
      rescue => e
        next
      end
    end

    nil
  end

  def format_content(html, url)
    doc = Nokogiri::HTML(html)

    open_links_in_new_tab(doc)
    convert_links_to_absolute(doc, url)

    doc.to_html
  end

  def get_raw_entry_data(entry_data)
    url = Url.normalize(entry_data.url)
    content = self.format_content(entry_data.content || entry_data.summary, url)
    description = entry_data.summary if entry_data.summary && entry_data.content

    {
      source_type: :rss,
      title: self.format_text(entry_data.title),
      description: self.format_text(description),
      author: self.format_text(entry_data.author),
      published_at: entry_data.published || Time.current,
      url: url,
      content: content,
      thumbnail_url: self.extract_thumbnail(content)
    }
  end

  def get_extracted_entry_data(url)
    parsed_data = ReadingParser.extract(url)
    return {} unless parsed_data

    content = self.format_content(parsed_data["content"], url)

    result = {
      content: content,
      thumbnail_url: self.extract_thumbnail(content),
      title: self.format_text(parsed_data["title"]),
      author: self.format_text(parsed_data["byline"]),
      published_at: (DateTime.parse(parsed_data["publishedTime"]) rescue nil)
    }

    result.compact
  end

  private

  def open_links_in_new_tab(doc)
    doc.css("a").each do |link|
      link["target"] = "_blank"
      link["rel"] = "noopener noreferrer"
    end
  end

  def convert_links_to_absolute(doc, origin_url)
    origin = Url.new(origin_url)

    doc.css("img, iframe, video, audio, source").each do |element|
      if element["src"] && !element["src"].empty?
        element["src"] = origin.to_absolute(element["src"])
      end
    end

    doc.css("object").each do |element|
      if element["data"] && !element["data"].empty?
        element["data"] = origin.to_absolute(element["data"])
      end
    end

    doc
  end

  def is_new?(stable_id)
    return false if Rails.cache.exist?("feed_entry:#{stable_id}")
    return false if Entry.exists?(stable_id: stable_id)
    true
  end

  def is_updated?(stable_id, new_fingerprint)
    return false if is_new?(stable_id)

    # Check cache first
    if Rails.cache.exist?("feed_entry:#{stable_id}")
      old_fingerprint = Rails.cache.read("feed_fingerprint:#{stable_id}")
      return old_fingerprint != new_fingerprint
    end

    # Fallback to database
    entry = Entry.find_by(stable_id: stable_id)
    return false unless entry

    old_fingerprint = entry.fingerprint
    old_fingerprint != new_fingerprint
  end

  def cache_entry(stable_id, fingerprint)
    Rails.cache.write("feed_entry:#{stable_id}", true, expires_in: cache_duration)
    update_entry_cache(stable_id, fingerprint)
  end

  def update_entry_cache(stable_id, fingerprint)
    Rails.cache.write("feed_fingerprint:#{stable_id}", fingerprint, expires_in: cache_duration)
  end
end
