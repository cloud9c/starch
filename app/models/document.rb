class Document < ApplicationRecord
  include SearchIndexable

  belongs_to :entry, optional: true
  has_one :channel, through: :entry
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states
  enum :source_type, [ :rss_original, :rss_extracted ]

  validates :content, length: { maximum: 100_000 }

  scope :visible_to_user, -> {
    where(id: Current.user.document_states.where(visible: true).select(:document_id))
  }

  scope :visible_to_user_with_status, ->(status) {
    where(id: Current.user.document_states.where(visible: true, status: status).select(:document_id))
  }

  scope :with_channel_details, -> {
    select("documents.*, channels.icon as channel_icon, channels.title as channel_title")
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

  def parsed_content
    parsed_data["content"] if parsed_data.present?
  end

  def parsed_title
    parsed_data["title"] if parsed_data.present?
  end

  def parsed_excerpt
    parsed_data["excerpt"] if parsed_data.present?
  end

  def parsed_author
    parsed_data["byline"] if parsed_data.present?
  end

  private

  def search_params
    {
      document_id: self.id,
      user_ids: DocumentState.where(document_id: self.id, visible: true).pluck(:user_id),
      title: self.title,
      description: self.description,
      url: self.url,
      published_at: self.published_at&.to_i,
      content: self.content
    }
  end
end
