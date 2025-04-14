class Document < ApplicationRecord
  include SearchIndexable

  belongs_to :entry, optional: true
  has_one :channel, through: :entry
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  enum :source_type, [ :rss ]

  validates :content, length: { maximum: 100_000 }

  @@per_page = 10

  def self.per_page
    @@per_page
  end

  def self.search(query, options = {})
    search_params = {
      q: query,
      query_by: "title,description,content",
      per_page: @@per_page,
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

  def self.query(user_id, options = {})
    query = Document.left_joins(:document_states)
                    .joins(entry: { channel: :subscriptions })
                    .includes(entry: :channel)
                    .order("document_states.read" => :asc, "documents.published_at" => :desc)

    if options[:status].present?
      query = query.where(document_states: { status: options[:status], user: user_id })
    else
      query = query.where(subscriptions: { user_id: user_id })
    end

    if options[:id].present?
      query = query.where(id: options[:ids])
    end

    if options[:page].present?
      query = query.limit(@@per_page)
                   .offset((options[:page] - 1) * @@per_page)
    end

    query = query.select("document_states.read, documents.*, subscriptions.view_extracted")

    query.map do |doc|
      doc.with_view_preferences
      doc.with_description
      doc
    end
  end

  def with_view_preferences
    should_extract =
      if self[:view_extracted]
        ActiveModel::Type::Boolean.new.cast(self[:view_extracted])
      else
        subscription = channel.subscriptions.select(:view_extracted).find_by(user_id: Current.user.id, channel_id: channel.id)
        subscription&.view_extracted
      end

    return self unless should_extract

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
