class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :feed
  has_many :entries, through: :feed
  has_many :documents, through: :entries

  validates :feed_id, presence: true, uniqueness: { scope: :user_id }

  scope :to_inbox, -> { where(to_inbox: true) }

  def add_recent_entries
    recent_entries = feed.entries.recent

    recent_entries.reverse_each do |entry|
      document = entry.document
      DocumentState.create(
        user_id: user_id,
        document: document,
        status: :inbox
      )

      # warm up extracted document
      ExtractDocumentJob.perform_later(document.id)
    end
  end
end
