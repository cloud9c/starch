class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :feed
  has_many :entries, through: :feed
  has_many :documents, through: :entries

  validates :feed_id, presence: true, uniqueness: { scope: :user_id }
  after_commit :destroy_feed_with_no_subscriptions, on: :destroy

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
    end
  end

  private
    def destroy_feed_with_no_subscriptions
      unless feed.subscriptions.exists?
        feed.destroy
      end
    end
end
