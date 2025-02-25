class Subscription < ApplicationRecord
  include UserOwnable

  belongs_to :channel
  has_many :subscriptions_tags, dependent: :destroy
  has_many :tags, through: :subscriptions_tags
  validates :channel_id, presence: true, uniqueness: { scope: :user_id }
  after_create :add_recent_entries

  private

  def add_recent_entries
    recent_entries = channel.entries.recent

    recent_entries.each do |entry|
      DocumentUserState.create(
        user_id: user_id,
        document: entry.document
      )
    end
  end
end
