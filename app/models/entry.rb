class Entry < ApplicationRecord
  has_one :document, dependent: :destroy
  belongs_to :feed

  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :feed, presence: true

  scope :recent, -> {
    includes(:document)
      .where.not(document: nil)
      .order("documents.published_at DESC, documents.created_at DESC")
      .limit(5)
  }

  def update_from_feed(entry_data)
    update!(fingerprint: EntryUtils.get_fingerprint(entry_data))
    update_document(entry_data)
    self
  end

  private

  def update_document(entry_data)
    raw_data = EntryUtils.get_raw_entry_data(entry_data)
    document.update!(raw_data)
  end
end
