class Entry < ApplicationRecord
  include Identifiable

  belongs_to :feed
  has_one :document, as: :source, dependent: :destroy

  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :feed, presence: true

  after_create :add_to_inbox

  scope :recent, -> {
    includes(:document)
      .where.not(document: nil)
      .order("documents.published_at DESC, documents.created_at DESC")
      .limit(5)
  }

  class << self
    def create_from_feed(entry_data, feed)
      entry = feed.entries.create(
        stable_id: get_stable_id(feed.feed_url, entry_data),
        fingerprint: get_fingerprint(entry_data)
      )

      raw_entry_data = parse_raw_entry_data(entry_data)
      document = entry.create_document!(raw_entry_data)
    end

    def update_from_feed(entry_data, feed_url)
      stable_id = get_stable_id(feed_url, entry_data)
      existing_entry = Entry.find_by(stable_id: stable_id)

      return unless existing_entry

      fingerprint = get_fingerprint(entry_data)
      existing_entry.update!(fingerprint: fingerprint)

      raw_data = parse_raw_entry_data(entry_data)
      existing_entry.document.update!(raw_data)
    end

    private
      def parse_raw_entry_data(entry_data)
        {
          title: entry_data.title,
          content: entry_data.content || entry_data.summary,
          description: (entry_data.summary && entry_data.content) ? entry_data.summary : nil,
          author: entry_data.author,
          published_at: entry_data.published,
          url: entry_data.url,
          thumbnail_url: entry_data.try(:media_thumbnail_url)
        }.compact
      end

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

      def add_to_inbox
        return if feed.created_at >= document.published_at

        users = feed.subscriptions.to_inbox.map(&:user).uniq
        return if users.empty?

        document_states = users.map do |user|
          { user: user, document: document, status: :inbox }
        end

        ExtractDocumentJob.perform_later(document.id)
        DocumentState.insert_all!(document_states)
        update_search_index
      end
  end
end
