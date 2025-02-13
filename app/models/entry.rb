class Entry < ApplicationRecord
  belongs_to :document, dependent: :destroy
  belongs_to :channel

  before_validation :update_ids
  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :document, presence: true, uniqueness: true
  validates :channel, presence: true

  attr_accessor :syndicate
  after_validation :create_document_user_states, if: :syndicate

  after_destroy :delete_document

  after_touch :update_ids

  scope :recent, -> {
    includes(:document)
      .order("documents.published_at DESC, documents.created_at DESC")
      .limit(5)
  }

  def create_document_user_states
    users = channel.users
    
    users.each do |user|
      DocumentUserState.create(
        user_id: user.id,
        document_id: self.document.id
      )
    end
  end

  def update_ids
    self.stable_id = EntryUtilities.get_stable_id(self.channel.feed_url, self.document)
    self.fingerprint = EntryUtilities.get_fingerprint(self.document)
  end

  def delete_document
    self.document.destroy
  end
end
