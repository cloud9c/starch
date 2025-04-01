class Document < ApplicationRecord
  include SearchIndexable

  belongs_to :entry, optional: true
  has_one :channel, through: :entry
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  enum :source_type, [ :rss ]

  validates :content, length: { maximum: 100_000 }

  def self.search(query, options = {})
    search_params = {
      q: query,
      query_by: "title,description,content",
      per_page: options[:per_page],
      page: options[:page],
      filter_by: "user_ids:=[#{Current.user_or_raise!.id}]",
      include_fields: "id"
    }

    result = self.search_collection.documents.search(search_params)
    result
  end

  def self.search_schema
    [
      { name: "user_ids", type: "int32[]" },
      { name: "title", type: "string", optional: true },
      { name: "description", type: "string", optional: true },
      { name: "url", type: "string", optional: true },
      { name: "published_at", type: "int64", optional: true },
      { name: "content", type: "string", optional: true }
    ]
  end

  def with_view_preferences
    if self[:view_extracted] == 0
      return self
    elsif self[:view_extracted].nil?
      subscription = channel.subscriptions.find_by(user_id: Current.user.id, channel_id: channel.id)
      return self unless subscription.view_extracted
    end

    unless extracted_data.blank?
      [ :title, :description, :content, :thumbnail_url ].each do |attr|
        self[attr] = extracted_data[attr] unless extracted_data[attr].blank?
      end
    end

    self
  end

  def with_description
    return self unless description.blank?

    if self.has_attribute?(:content)
      preview_text = EntryUtils.format_text(self.content.strip.gsub(/\s+/, " "))[0...300]
      self.description = preview_text
    end

    self
  end

  def extracted_data
    return {} unless url

    Rails.cache.fetch("#{cache_key_with_version}/extracted_data", expires_in: 7.day) do
      result = EntryUtils.get_extracted_entry_data(url)

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
