module Entry::Identifiable
  extend ActiveSupport::Concern

  CACHE_DURATION = 7.days
  ENTRY_LIMIT = 300

  class_methods do
    def find_parsed_entry_by_stable_id(stable_id, parsed_feed, feed_url)
      parsed_feed.entries.find do |parsed_entry|
        get_stable_id(feed_url, parsed_entry) == stable_id
      end
    end

    def get_new_entries(feed_url, parsed_feed)
      new_entries = []

      sorted_entries = get_recent_entries(parsed_feed, ENTRY_LIMIT)

      sorted_entries.each do |parsed_entry|
        stable_id = get_stable_id(feed_url, parsed_entry)

        if is_new?(stable_id)
          new_entries << parsed_entry
          cache_entry(stable_id)
        end
      end

      new_entries
    end

    def get_stable_id(feed_url, parsed_entry)
      parts = []
      parts << feed_url

      if parsed_entry.id.present?
        parts << parsed_entry.id
      else
        if parsed_entry.url
          uri = URI(parsed_entry.url)
          result = [ uri.userinfo, uri.path, uri.query, uri.fragment ].compact.join
          without_protocol_and_host = (result.empty? || result == "/") ? uri.to_s : result
          parts << without_protocol_and_host
        end

        parts << parsed_entry.published.iso8601 if parsed_entry.published
        parts << parsed_entry.title if parsed_entry.title
      end

      Digest::SHA1.hexdigest(parts.compact.join)
    end

    private
      def get_recent_entries(parsed_feed, limit = 5)
        parsed_feed.entries.reverse.sort_by do |parsed_entry|
          parsed_entry.published || Time.at(0)
        end.last(limit)
      end

      def cache_entry(stable_id)
        Rails.cache.write("entry/stable_id/#{stable_id}", true, expires_in: CACHE_DURATION)
      end

      def is_new?(stable_id)
        return false if Rails.cache.exist?("entry/stable_id/#{stable_id}")
        return false if Entry.exists?(stable_id: stable_id)
        true
      end
  end
end
