class Document < ApplicationRecord
  include SearchIndexable

  has_one :entry, dependent: :destroy, touch: true
  has_one :channel, through: :entry
  has_many :document_user_states, dependent: :destroy
  has_many :users, through: :document_user_states

  validates :content, length: { maximum: 100_000 }

  after_save :parse_content, if: :should_parse_content?

  scope :owned_by_user, -> {
    where(id: DocumentUserState.select(:document_id))
  }

  scope :with_channel_details, -> {
    select("documents.*, channels.icon as channel_icon, channels.title as channel_title")
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

    begin
      collection = SearchEngine.client.collections[search_collection_name]
      result = collection.documents.search(search_params)
      result
    rescue Typesense::Error::ObjectNotFound
      create_collection
      { hits: [] }
    end
  end

  def self.create_collection
    SearchEngine.client.collections.create({
      name: search_collection_name,
      fields: [
        { name: "document_id", type: "int32", index: false },
        { name: "user_ids", type: "int32[]" }, # Changed to array type
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

  private

  def search_params
    {
      document_id: self.id,
      user_ids: DocumentUserState.where(document_id: self.id).pluck(:user_id),
      title: self.title,
      description: self.description,
      url: self.url,
      published_at: self.published_at&.to_i,
      content: self.content
    }
  end

  def should_parse_content?
    saved_change_to_content? || saved_change_to_url?
  end

  def parse_content
    ParseDocumentJob.perform_now(self.id)
  end
end
