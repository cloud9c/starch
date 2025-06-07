class Entry < ApplicationRecord
  belongs_to :feed
  has_one :document, as: :source, dependent: :destroy

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
    raw_data = EntryUtils.get_raw_entry_data(entry_data)
    document.update!(raw_data)
    self
  end
end
