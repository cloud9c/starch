module EntryHelper
  extend self

  mattr_reader :cache_duration, default: 7.days

  def get_stable_id(feed_url, entry)
    parts = []
    parts << feed_url

    if entry.id.present?
      parts << entry.id
    else
      parts << HttpHelper.remove_protocol_and_host(entry.url) if entry.url
      parts << entry.published.iso8601 if entry.published
      parts << entry.title if entry.title
    end

    Digest::SHA1.hexdigest(parts.compact.join)
  end

  def get_fingerprint(entry)
    Digest::MD5.hexdigest([
      entry.title,
      entry.content,
      entry.author
    ].compact.join)
  end

  def get_new_and_updated(feed_url, feed_content)
    feed = FeedHelper.parse(feed_content) rescue nil

    Rails.logger.error "Failed to parse feed content for URL: #{feed_url}" unless feed

    return { new: [], updated: [] } unless feed

    new_entries = []
    updated_entries = []

    feed.entries.each do |entry|
      stable_id = get_stable_id(feed_url, entry)
      fingerprint = get_fingerprint(entry)

      if is_new?(stable_id)
        new_entries << entry
        cache_entry(stable_id, fingerprint)
      elsif is_updated?(stable_id, fingerprint)
        updated_entries << entry
        update_entry_cache(stable_id, fingerprint)
      end
    end

    { new: new_entries, updated: updated_entries }
  end

  def decode_text(text)
    CGI.unescapeHTML(text)
  end

  private

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
