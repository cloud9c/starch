class Entry < ApplicationRecord
  has_many :documents, dependent: :destroy
  belongs_to :channel

  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :channel, presence: true

  scope :recent, ->(source_type) {
    includes(:documents)
      .where(documents: { source_type: source_type })
      .order("documents.published_at DESC, documents.created_at DESC")
      .limit(5)
  }

  def self.create_from_feed(channel, entry_data)
    entry = new(
      channel: channel,
      stable_id: EntryHelper.get_stable_id(channel.feed_url, entry_data),
      fingerprint: EntryHelper.get_fingerprint(entry_data)
    )

    entry.save!
    entry.create_documents(entry_data)
    entry
  end

  def update_from_feed(entry_data)
    update!(fingerprint: EntryHelper.get_fingerprint(entry_data))
    update_documents(entry_data)
    self
  end

  def get_raw_entry_data(entry_data)
    {
      source_type: 'rss_original',
      title: EntryHelper.format_text(entry_data.title),
      description: EntryHelper.format_text(entry_data.summary),
      author: EntryHelper.format_text(entry_data.author),
      published_at: entry_data.published,
      url: HttpHelper.normalize_url(entry_data.url),
      content: entry_data.content,
      thumbnail_url: EntryHelper.extract_thumbnail(entry_data.content)
    }
  end

  def get_extracted_entry_data(entry_data)
    result = get_raw_entry_data(entry_data)

    extracted_data = ReadingParser.extract(entry_data.url)

    return unless extracted_data

    cleaned_data = {
      title: EntryHelper.format_text(extracted_data["title"]),
      description: EntryHelper.format_text(extracted_data["excerpt"]),
      published_at: extracted_data["publishedTime"],
      content: extracted_data["content"],
      thumbnail_url: EntryHelper.extract_thumbnail(extracted_data["content"])
    }.compact

    return nil if cleaned_data.empty?
    
    result[:source_type] = 'rss_extracted'
    result.merge!(cleaned_data)
  end

  def create_documents(entry_data)
    original_data = get_raw_entry_data(entry_data)
    documents.create!(original_data)
    
    extracted_data = get_extracted_entry_data(entry_data)
    documents.create!(extracted_data) if extracted_data
  end

  def update_documents(entry_data)
    original_data = get_raw_entry_data(entry_data)
    original_doc = documents.find_by!(source_type: 'rss_original')
    original_doc.update!(original_data)
    
    extracted_data = get_extracted_entry_data(entry_data)
    if extracted_data
      extracted_doc = documents.find_by!(source_type: 'rss_extracted')
      extracted_doc.update!(extracted_data)
    end
  end
end