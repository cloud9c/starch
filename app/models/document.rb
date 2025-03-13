class Document < ApplicationRecord
  include SearchIndexable

  belongs_to :entry, optional: true
  has_one :channel, through: :entry
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  enum :source_type, [ :rss ]

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

  scope :with_subscription_info, -> {
    select("documents.*, COALESCE(subscriptions.view_extracted, false) as subscription_view_extracted")
      .left_joins(entry: { channel: :subscriptions })
      .where("subscriptions.user_id = ? OR subscriptions.user_id IS NULL", Current.user&.id)
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

  def get_attribute(attribute)
    Rails.logger.debug "extracted_data: #{extracted_data}"
    if subscription_view_extracted? && extracted_data.present? && extracted_data[attribute].present?
      extracted_data[attribute]
    else
      self[attribute]
    end
  end

  def extracted_data
    return {} unless url

    Rails.cache.fetch("#{cache_key_with_version}/extracted_data", expires_in: 1.day) do
      parsed_data = ReadingParser.extract(url)
      next {} unless parsed_data

      {
        title: parsed_data["title"],
        description: parsed_data["excerpt"],
        content: parsed_data["content"],
        thumbnail_url: EntryHelper.extract_thumbnail(parsed_data["content"])
      }.compact
    end
  end

  private

  def search_attributes
    {
      id: self.id.to_s,
      user_ids: DocumentState.where(document_id: self.id).pluck(:user_id),
      title: self.title,
      description: self.description,
      url: self.url,
      published_at: self.published_at&.to_i,
      content: self[:content]
    }
  end
end
