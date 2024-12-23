class Page < ApplicationRecord
 belongs_to :channel
 validates :channel, presence: true
 validates :url, presence: true, uniqueness: true
 validates :content, length: { maximum: 100_000 }
 after_create :index_in_typesense
 after_update :update_typesense_index
 after_destroy :remove_from_typesense

 def self.typesense_schema
   {
     name: "pages",
     fields: [
       { name: "title", type: "string" },
       { name: "description", type: "string" },
       { name: "url", type: "string" },
       { name: "published_at", type: "int64" },  # store as Unix timestamp
       { name: "content", type: "string" },
       { name: "channel_id", type: "string", index: false }
     ]
   }
 end

 def self.search(query, options = {})
    search_params = {
      q: query,
      query_by: "title,description,content",
      # sort_by: 'published_at:desc',
      per_page: options[:per_page] || 20,
      page: options[:page] || 1,
    }

   # Add optional filters if provided
   # search_params[:filter_by] = options[:filter_by] if options[:filter_by]

   begin
     TypesenseClient.client.collections["pages"]
              .documents
              .search(search_params)
   rescue Typesense::Error::ObjectNotFound
     Rails.logger.error "Typesense collection 'pages' not found"
     { hits: [] }
   end
 end

 private

 def index_in_typesense
   begin
     TypesenseClient.client.collections["pages"].documents.create({
       id: id.to_s,
       title: title,
       description: description,
       url: url,
       published_at: published_at.to_i,
       content: content,
       channel_id: channel_id
     })
   rescue Typesense::Error => e
     Rails.logger.error "Failed to index page #{id} in Typesense: #{e.message}"
   end
 end

 def update_typesense_index
   begin
     TypesenseClient.client.collections["pages"].documents[id.to_s].update({
       title: title,
       description: description,
       url: url,
       published_at: published_at.to_i,
       content: content,
       channel_id: channel_id
     })
   rescue Typesense::Error::ObjectNotFound
     # If document doesn't exist, create it
     index_in_typesense
   rescue Typesense::Error => e
     Rails.logger.error "Failed to update page #{id} in Typesense: #{e.message}"
   end
 end

 def remove_from_typesense
   begin
     TypesenseClient.client.collections["pages"].documents[id.to_s].delete
   rescue Typesense::Error::ObjectNotFound
     Rails.logger.info "Typesense record #{id} not found for deletion"
   rescue Typesense::Error => e
     Rails.logger.error "Failed to remove page #{id} from Typesense: #{e.message}"
   end
 end
end
