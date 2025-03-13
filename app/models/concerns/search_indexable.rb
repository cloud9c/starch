module SearchIndexable
  extend ActiveSupport::Concern

  included do
    after_create :create_search_index
    after_update :update_search_index
    after_destroy :remove_search_index
  end

  def update_search_index
    SearchEngine.client.collections[self.class.search_collection_name]
                  .documents[id.to_s]
                  .update(search_attributes)
  end

  def upsert_search_index
    SearchEngine.client.collections[self.class.search_collection_name]
                  .documents
                  .upsert(search_attributes)
  end

  private

  def create_search_index
    SearchEngine.client.collections[self.class.search_collection_name]
                  .documents
                  .create(search_attributes)
  end

  def remove_search_index
    SearchEngine.client.collections[self.class.search_collection_name]
                  .documents[id.to_s]
                  .delete
  end

  def search_attributes
    raise NotImplementedError, "#{self.class} must implement search_attributes method"
  end

  def search_document
    SearchEngine.client.collections[self.class.search_collection_name]
  end

  class_methods do
    def search_collection_name
      model_name.plural
    end

    def search(query, options = {})
      raise NotImplementedError, "#{self} must implement search class method"
    end

    def create_search_collection
      raise NotImplementedError, "#{self} must implement create_collection class method"
    end

    def search_collection
      SearchEngine.client.collections[self.class.search_collection_name]
    end
  end
end
