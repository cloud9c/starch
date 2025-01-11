class Subscription < ApplicationRecord
  include UserOwnable

  belongs_to :channel
  belongs_to :folder, optional: true
  validates :channel_id, presence: true, uniqueness: { scope: :user_id }
  after_create :add_recent_entries

  private

  def add_recent_entries
    recent_entries = channel.entries.unscoped_recent

    logger.debug "RECENT #: #{recent_entries.count}"

    states = recent_entries.map do |entry|
      {
        user_id: user_id,
        document_id: entry.document_id,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    DocumentUserState.insert_all(states) if states.any?
  end
end
