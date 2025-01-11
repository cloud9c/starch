class Entry < ApplicationRecord
  belongs_to :document
  belongs_to :channel

  before_validation :update_ids
  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :document, presence: true, uniqueness: true
  validates :channel, presence: true
  after_validation :create_document_user_states

  after_touch :update_ids

  scope :unscoped_recent, -> {
    where(
      document_id: Document
        .unscoped
        .order(published_at: :desc)
        .order(created_at: :desc)
        .limit(5)
        .select(:id)
    )
  }

  def create_document_user_states
    users = channel.users

    states = users.map do |user|
      {
        user_id: user.id,
        document_id: self.document.id,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    DocumentUserState.insert_all!(states)
  end

  def update_ids
    self.stable_id = EntryUtilities.get_stable_id(self.channel.feed_url, self.document)
    self.fingerprint = EntryUtilities.get_fingerprint(self.document)
  end
end
