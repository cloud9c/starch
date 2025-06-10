module Entry::Identifiable
  extend ActiveSupport::Concern

  CACHE_DURATION = 7.days
  ENTRY_LIMIT = 300

  class_methods do
    def get_new_and_updated(feed_url, feed_content)
      return { new: [], updated: [] } unless feed_content

      new_entries = []
      updated_entries = []

      # Process entries in reverse order so oldest come first
      feed_content.entries.first(ENTRY_LIMIT).reverse_each do |entry_data|
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

    def get_stable_id(feed_url, entry_data)
      parts = []
      parts << feed_url

      if entry_data.id.present?
        parts << entry_data.id
      else
        if entry_data.url
          uri = URI(entry_data.url)
          result = [ uri.userinfo, uri.path, uri.query, uri.fragment ].compact.join
          without_protocol_and_host = (result.empty? || result == "/") ? uri.to_s : result
          parts << without_protocol_and_host
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

    private
      def cache_entry(stable_id, fingerprint)
        Rails.cache.write("entry/stable_id/#{stable_id}", true, expires_in: CACHE_DURATION)
        update_entry_cache(stable_id, fingerprint)
      end

      def update_entry_cache(stable_id, fingerprint)
        Rails.cache.write("entry/stable_id/#{stable_id}/fingerprint", fingerprint, expires_in: CACHE_DURATION)
      end
  end
end
