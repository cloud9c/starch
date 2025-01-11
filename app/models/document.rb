class Document < ApplicationRecord
  has_one :entry, dependent: :destroy, touch: true
  has_one :channel, through: :entry
  has_many :document_user_states, dependent: :destroy
  has_many :users, through: :document_user_states

  validates :content, length: { maximum: 100_000 }

  after_create :index_in_typesense
  after_update :update_typesense_index
  after_destroy :remove_from_typesense

  default_scope -> {
    where(id: DocumentUserState.select(:document_id))
  }

  COLLECTION_NAME = "documents"

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
      collection = TypesenseClient.client.collections[COLLECTION_NAME]
      result = collection.documents.search(search_params)
      Rails.logger.debug "Search result: #{result.inspect}"
      result
    rescue Typesense::Error::ObjectNotFound
      create_collection
      { hits: [] }
    end
  end

  def self.create_collection
    TypesenseClient.client.collections.create({
      name: COLLECTION_NAME,
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

  def update_typesense_index
    ensure_collection_exists
    TypesenseClient.client.collections[COLLECTION_NAME]
                  .documents[id.to_s]
                  .update(document_params)
  rescue Typesense::Error::ObjectNotFound
    index_in_typesense
  rescue Typesense::Error => e
    Rails.logger.error "Failed to update document #{id}: #{e.message}"
  end

  private

  def document_params
    {
      document_id: self.id,
      user_ids: self.document_user_states.pluck(:user_id), # Get array of user IDs
      title: self.title,
      description: self.description,
      url: self.url,
      published_at: self.published_at&.to_i,
      content: self.content
    }
  end

  def index_in_typesense
    ensure_collection_exists
    TypesenseClient.client.collections[COLLECTION_NAME]
                  .documents
                  .create(document_params)
  rescue Typesense::Error => e
    Rails.logger.error "Failed to index document #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def update_user_index
    update_typesense_index if persisted?
  end

  def remove_from_typesense
    TypesenseClient.client.collections[COLLECTION_NAME]
                  .documents[id.to_s]
                  .delete
  rescue Typesense::Error::ObjectNotFound
    Rails.logger.info "Document #{id} not found for deletion"
  rescue Typesense::Error => e
    Rails.logger.error "Failed to remove document #{id}: #{e.message}"
  end

  def ensure_collection_exists
    TypesenseClient.client.collections[COLLECTION_NAME].retrieve
  rescue Typesense::Error::ObjectNotFound
    self.class.create_collection
  end
end
