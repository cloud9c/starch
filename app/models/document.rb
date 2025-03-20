class Document < ApplicationRecord
  include SearchIndexable

  belongs_to :entry, optional: true
  has_one :channel, through: :entry
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  enum :source_type, [ :rss ]

  validates :content, length: { maximum: 100_000 }

  scope :owned_by_user, ->(status = nil) {
    query = Current.user.document_states
    query = query.where(status: status) if status.present?
    where(id: query.select(:document_id))
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
    result
  end

  def self.create_search_collection
    SearchEngine.client.collections.create({
      name: search_collection_name,
      fields: [
        { name: "user_ids", type: "int32[]" },
        { name: "title", type: "string", optional: true },
        { name: "description", type: "string", optional: true },
        { name: "url", type: "string", optional: true },
        { name: "published_at", type: "int64", optional: true },
        { name: "content", type: "string", optional: true }
      ]
    })
  end

  def view_extracted?
    return @view_extracted unless @view_extracted.nil?

    subscription = channel&.subscriptions&.find_by(user_id: Current.user&.id)
    @view_extracted = if subscription
      cache_key = "subscription/#{subscription.id}/#{subscription.updated_at.to_i}/view_extracted"
      Rails.cache.fetch(cache_key, expires_in: 1.hour) { subscription.view_extracted || false }
    else
      false
    end
  end

  def with_view_preferences
    return self unless view_extracted?

    if !extracted_data.empty?
      [ :title, :description, :content, :thumbnail_url ].each do |attr|
        self[attr] = extracted_data[attr] if extracted_data[attr].present?
      end
    end

    self
  end

  def extracted_data
    return {} unless url

    Rails.cache.fetch("#{cache_key_with_version}/extracted_data", expires_in: 7.day) do
      result = EntryHelper.get_extracted_entry_data(url)

      result.delete(:title) if self.title
      result.delete(:author) if self.author
      result.delete(:published_at) if self.published_at

      result
    end
  end

  private

  def search_attributes
    {
      id: id.to_s,
      user_ids: DocumentState.where(document_id: self.id).pluck(:user_id),
      title: title,
      description: description,
      url: url,
      published_at: published_at&.to_i,
      content: content
    }
  end
end
