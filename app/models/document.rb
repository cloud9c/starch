class Document < ApplicationRecord
  include SearchIndexable

  belongs_to :entry, optional: true
  has_one :channel, through: :entry
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  # Changed from source_type enum to a single type
  enum :source_type, [ :rss ]

  after_update :clear_extracted_cache, if: :url_changed?

  validates :content, length: { maximum: 100_000 }

  scope :owned_by_user, -> {
    where(id: Current.user.document_states.select(:document_id))
  }

  scope :owned_by_user_with_status, ->(status) {
    where(id: Current.user.document_states.where(status: status).select(:document_id))
  }

  scope :with_channel_details, -> {
    select("documents.*, channels.icon as channel_icon, channels.title as channel_title, channels.id as channel_id")
      .left_joins(entry: :channel)
      .order(published_at: :desc)
  }

  scope :with_channel_icon, -> {
    select("documents.*, channels.icon as channel_icon")
      .left_joins(entry: :channel)
      .order(published_at: :desc)
  }

  def self.search(query, options = {})
    search_params = {
      q: query,
      query_by: "title,description,content",
      per_page: options[:per_page] || 20,
      page: options[:page] || 1,
      filter_by: "user_ids:=[#{Current.user_or_raise!.id}]",
      select_fields: "document_id"
    }
    collection = SearchEngine.client.collections[search_collection_name]
    result = collection.documents.search(search_params)
    Rails.logger.debug "THIS IS THE RESULT #{result.to_json}"
    result
  end

  def self.create_collection
    SearchEngine.client.collections.create({
      name: search_collection_name,
      fields: [
        { name: "document_id", type: "int32", index: false },
        { name: "user_ids", type: "int32[]" },
        { name: "title", type: "string", optional: true },
        { name: "description", type: "string", optional: true },
        { name: "url", type: "string", optional: true },
        { name: "published_at", type: "int64", optional: true },
        { name: "content", type: "string", optional: true }
      ]
    })
  rescue Typesense::Error => e
    Rails.logger.error "Failed to create collection: #{e.message}"
  end

  def get_attribute(attribute)
    if show_extracted? && extracted_data.present? && extracted_data[attribute].present?
      extracted_data[attribute]
    else
      self[attribute]
    end
  end

  def show_extracted?
    subscription = Subscription.find_by(
      user_id: Current.user&.id,
      channel_id: entry&.channel_id
    )
    subscription&.view_extracted || false
  end

  def extracted_data
    return {} unless url

    Rails.cache.fetch("document_extracted_#{id}", expires_in: 7.days) do
      extracted_data = ReadingParser.extract(url)
      return unless extracted_data

      {
        content: extracted_data["content"],
        thumbnail_url: EntryHelper.extract_thumbnail(extracted_data["content"])
      }.compact
    end
  end

  private

  def search_params
    {
      document_id: self.id,
      user_ids: DocumentState.where(document_id: self.id).pluck(:user_id),
      title: self.title,
      description: self.description,
      url: self.url,
      published_at: self.published_at&.to_i,
      content: self[:content] # Use the database content for search indexing
    }
  end

  def clear_extracted_cache
    Rails.cache.delete("document_extracted_#{id}")
  end
end
