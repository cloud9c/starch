module Document::Searchable
  extend ActiveSupport::Concern

  included do
    after_create :upsert_search_index
    after_update :update_search_index
    after_destroy :destroy_search_index
  end

  class_methods do
    def search_collection_name
      model_name.plural
    end

    def search(query, options = {})
      return [] if query.empty?

      search_params = {
        q: query,
        query_by: "title,description,content",
        per_page: options[:per_page],
        page: options[:page],
        filter_by: "user_id:=#{Current.user_or_raise!.id}",
        include_fields: "id"
      }

      result = self.search_collection.documents.search(search_params)
      result["hits"]
            .map { |hit| hit.dig("document", "id") }
            .compact
            .uniq
    end

    def search_schema
      [
        { name: "user_id", type: "int32" },
        { name: "title", type: "string", optional: true },
        { name: "description", type: "string", optional: true },
        { name: "published_at", type: "int64", optional: true },
        { name: "content", type: "string", optional: true }
      ]
    end

    def create_search_collection
      SearchEngine.client.collections.create({
        name: self.search_collection_name,
        fields: self.search_schema
      })
    end

    def search_collection
      SearchEngine.client.collections[search_collection_name]
    end
  end

  def update_search_index
    self.class.search_collection.documents[id.to_s].update(search_attributes)
  rescue Typesense::Error::ObjectNotFound
    false
  end

  def upsert_search_index
    self.class.search_collection.documents.upsert(search_attributes)
  end

  private
    def destroy_search_index
      self.class.search_collection.documents[id.to_s].delete
    rescue Typesense::Error::ObjectNotFound
      false
    end

    def search_attributes
      raise NotImplementedError, "#{self.class} must implement search_attributes method"
    end

    def search_attributes
      {
        id: id.to_s,
        user_id: user.id,
        title: title,
        description: description,
        published_at: published_at&.to_i,
        content: Nokogiri::HTML(content).text.truncate(5000)
      }
    end
end
