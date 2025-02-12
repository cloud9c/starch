module SearchIndexable
  extend ActiveSupport::Concern

  included do
    after_create :create_search_index
    after_update :update_search_index
    after_destroy :remove_search_index

    SearchEngine.register_collection(self)
  end

  def update_search_index
    ensure_collection_exists
    SearchEngine.client.collections[self.class.search_collection_name]
                  .documents[id.to_s]
                  .update(search_params)
  rescue Typesense::Error::ObjectNotFound
    create_search_index
  rescue Typesense::Error => e
    Rails.logger.error "Failed to update document #{id}: #{e.message}"
  end

  private

  def create_search_index
    ensure_collection_exists
    SearchEngine.client.collections[self.class.search_collection_name]
                  .documents
                  .create(search_params)
  rescue Typesense::Error => e
    Rails.logger.error "Failed to index document #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def remove_search_index
    SearchEngine.client.collections[self.class.search_collection_name]
                  .documents[id.to_s]
                  .delete
  rescue Typesense::Error::ObjectNotFound
    Rails.logger.info "Document #{id} not found for deletion"
  rescue Typesense::Error => e
    Rails.logger.error "Failed to remove document #{id}: #{e.message}"
  end

  def ensure_collection_exists
    SearchEngine.client.collections[self.class.search_collection_name].retrieve
  rescue Typesense::Error::ObjectNotFound
    self.class.create_collection
  end

  def search_params
    raise NotImplementedError, "#{self.class} must implement search_params"
  end

  class_methods do
    def search_collection_name
      model_name.plural
    end

    def search(query, options = {})
      raise NotImplementedError, "#{self} must implement search class method"
    end

    def create_collection
      raise NotImplementedError, "#{self} must implement create_collection class method"
    end
  end
end