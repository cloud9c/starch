class Subscription < ApplicationRecord
  include UserOwnable

  belongs_to :channel
  has_many :subscriptions_tags, dependent: :destroy
  has_many :tags, through: :subscriptions_tags

  has_many :entries, through: :channel
  has_many :documents, through: :entries

  validates :channel_id, presence: true, uniqueness: { scope: :user_id }
  after_create :add_recent_entries
  after_save :expire_document_caches, if: :view_extracted_changed?

  private

  def add_recent_entries
    recent_entries = channel.entries.recent

    recent_entries.each do |entry|
      document = entry.document
      DocumentState.create(
        user_id: user_id,
        document: document
      )
    end
  end

  def expire_document_caches
  end
end
