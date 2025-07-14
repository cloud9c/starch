class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :feed
  has_many :entries, through: :feed
  has_many :documents, through: :entries

  validates :feed_id, presence: true, uniqueness: { scope: :user_id }

  scope :to_inbox, -> { where(to_inbox: true) }
end
