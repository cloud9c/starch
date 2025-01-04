class Subscription < ApplicationRecord
  include UserOwnable

  belongs_to :channel
  belongs_to :folder, optional: true
  validates :channel_id, presence: true, uniqueness: { scope: :user_id }
end
