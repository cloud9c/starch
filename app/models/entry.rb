class Entry < ApplicationRecord
  has_one :document, dependent: :destroy
  belongs_to :channel

  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :channel, presence: true

  attr_accessor :syndicate

  after_create :upsert_document
  after_save :upsert_document, if: :saved_change_to_url?

  scope :recent, -> {
    includes(:document)
      .order("documents.published_at DESC, documents.created_at DESC")
      .limit(5)
  }

  def upsert_document
    UpsertDocumentFromEntry.perform_now(self.id, syndicate || false)
  end
end
