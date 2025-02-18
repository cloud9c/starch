class Subscription < ApplicationRecord
  include UserOwnable

  belongs_to :channel
  belongs_to :folder, optional: true
  validates :channel_id, presence: true, uniqueness: { scope: :user_id }
  after_create :add_recent_entries

  private

  def add_recent_entries
    recent_entries = channel.entries.recent

    recent_entries.each do |entry|
      DocumentUserState.create(
        user_id: user_id,
        document_id: entry.document_id
      )
    end
  end
end
