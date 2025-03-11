class Entry < ApplicationRecord
  has_one :document, dependent: :destroy
  belongs_to :channel

  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :channel, presence: true

  scope :recent, -> {
    includes(:document)
      .where.not(document: nil)
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

    raw_entry_data = get_raw_entry_data(entry_data)
    document = entry.create_document(raw_entry_data)

    # warm up extracted_content
    document.extracted_data

    entry
  end

  def self.get_raw_entry_data(entry_data)
    content = entry_data.content || entry_data.summary
    description = if entry_data.summary.present?
      entry_data.summary
    elsif content.present?
      clean_content = EntryHelper.format_text(content)
      clean_content.slice(0, 150) + (clean_content.length > 150 ? "..." : "")
    end

    {
      source_type: :rss,
      title: EntryHelper.format_text(entry_data.title),
      description: EntryHelper.format_text(description),
      author: EntryHelper.format_text(entry_data.author),
      published_at: entry_data.published,
      url: HttpHelper.normalize_url(entry_data.url),
      content: content,
      thumbnail_url: EntryHelper.extract_thumbnail(content)
    }
  end

  def update_from_feed(entry_data)
    update!(fingerprint: EntryHelper.get_fingerprint(entry_data))
    update_document(entry_data)
    self
  end

  private

  def update_document(entry_data)
    raw_data = get_raw_entry_data(entry_data)
    document.update!(raw_data)
  end
end
