class Session < ApplicationRecord
  belongs_to :user
  has_secure_token :device_token

  scope :temporary, -> { where(verified_at: nil) }

  def self.sweep(time = 24.hour)
    where(updated_at: ...time.ago)
      .or(where(created_at: ...2.weeks.ago))  # Max age
      .delete_all
  end
end
