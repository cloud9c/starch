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
    query = Document.left_joins(entry: { channel: :subscriptions })
                    .includes(entry: { channel: :subscriptions })

    if options[:page].present?
      query = query.limit(@@per_page)
                   .offset((options[:page] - 1) * @@per_page)
    end

    if options[:status].present?
      query = query.joins(:document_states)
                   .where(document_states: { user_id: user_id, status: options[:status] })
                   .order("document_states.read" => :asc, "document_states.updated_at" => :desc)

      query = query.select("document_states.read")
    elsif options[:ids].present?
      query = query.where(id: options[:ids])
    else
      query = query.where(subscriptions: { user_id: user_id })
    end

    query = query.order("documents.published_at" => :desc)

    query = query.select("documents.*, subscriptions.view_extracted")

    query.map do |doc|
      doc.with_view_preferences(skip_wait: true)
        .force_description
    end
  end

  def force_description
    unless self[:description].present?
      self[:description] = EntryUtils.format_description(content)
    end

    self
  end

  def with_view_preferences(skip_wait: false)
    should_extract =
      if self[:view_extracted].present?
        ActiveModel::Type::Boolean.new.cast(self[:view_extracted])
      else
        subscription = channel&.subscriptions&.find { |s| s.user_id == Current.user.id }
        subscription&.view_extracted
      end

    if !should_extract
      self.description = EntryUtils.format_description(content)
      return self
    elsif skip_wait && !Rails.cache.exist?("#{cache_key_with_version}/extracted_data")
      ExtractDocumentJob.perform_later(self.id)
      return self
    end

    preferences = {
      thumbnail_url: extracted_data[:thumbnail_url],
      content: extracted_data[:content],
      published_at: self.published_at || extracted_data[:published_at],
      title: self.title || extracted_data[:title],
      author: self.author || extracted_data[:author]
    }.compact

    preferences.each do |attr, value|
      self[attr] = value unless value.nil?
    end

    self
  end

  def extracted_data
    return {} unless url

    cache_key = "#{cache_key_with_version}/extracted_data"
    result = Rails.cache.fetch(cache_key, expires_in: 7.day) do
      EntryUtils.get_extracted_entry_data(url)
    end

    result
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
      content: Nokogiri::HTML(content).text
    }
  end
end
