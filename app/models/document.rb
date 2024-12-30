class Document < ApplicationRecord
  belongs_to :user
  belongs_to :channel, optional: true
  validates :content, length: { maximum: 100_000 }

  after_create :index_in_typesense
  after_update :update_typesense_index
  after_destroy :remove_from_typesense

  def self.collection_name(user_id)
    "documents_user_#{user_id}"
  end

  def self.search(query, options = {})
    raise ArgumentError, "user_id is required" unless options[:user_id]

    collection = TypesenseClient.client.collections[collection_name(options[:user_id])]

    search_params = {
      q: query,
      query_by: "title,description,content",
      per_page: options[:per_page] || 20,
      page: options[:page] || 1
    }

    begin
      result = collection.documents.search(search_params)
      Rails.logger.debug "Search result: #{result.inspect}"
      result
    rescue Typesense::Error::ObjectNotFound
      create_collection_for_user(options[:user_id])
      { hits: [] }
    end
  end

  def self.create_collection_for_user(user_id)
    TypesenseClient.client.collections.create({
      name: collection_name(user_id),
      fields: [
        { name: "document_id", type: "int32", index: false },
        { name: "title", type: "string", optional: true },
        { name: "description", type: "string", optional: true },
        { name: "url", type: "string", optional: true },
        { name: "published_at", type: "int64", optional: true },
        { name: "content", type: "string", optional: true },
        { name: "channel_id", type: "int32", index: false }
      ]
    })
  rescue Typesense::Error => e
    Rails.logger.error "Failed to create collection for user #{user_id}: #{e.message}"
  end

  private

  def document_params
    {
      document_id: self.id,
      title: self.title,
      description: self.description,
      url: self.url,
      published_at: self.published_at&.to_i,
      content: self.content,
      channel_id: self.channel_id
    }
  end

  def index_in_typesense
    ensure_collection_exists

    result = TypesenseClient.client.collections[collection_name]
              .documents
              .create(document_params)
  rescue Typesense::Error => e
    Rails.logger.error "Failed to index document #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") # Add full backtrace
  end

  def update_typesense_index
    ensure_collection_exists

    TypesenseClient.client.collections[collection_name]
              .documents[id.to_s]
              .update(document_params)
  rescue Typesense::Error::ObjectNotFound
    index_in_typesense
  rescue Typesense::Error => e
    Rails.logger.error "Failed to update document #{id}: #{e.message}"
  end

  def remove_from_typesense
    TypesenseClient.client.collections[collection_name]
              .documents[id.to_s]
              .delete
  rescue Typesense::Error::ObjectNotFound
    Rails.logger.info "Document #{id} not found for deletion"
  rescue Typesense::Error => e
    Rails.logger.error "Failed to remove document #{id}: #{e.message}"
  end

  def collection_name
    self.class.collection_name(user_id)
  end

  def ensure_collection_exists
    TypesenseClient.client.collections[collection_name].retrieve
  rescue Typesense::Error::ObjectNotFound
    self.class.create_collection_for_user(user_id)
  end
end
