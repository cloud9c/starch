class Session < ApplicationRecord
  belongs_to :user, optional: true

  ACTIVITY_THRESHOLD = 30.days
  EXPIRATION_THRESHOLD = 90.days

  scope :active, -> {
    where.not(user_id: nil)
    .where(updated_at: ACTIVITY_THRESHOLD.ago..)
    .where(created_at: EXPIRATION_THRESHOLD.ago..)
  }
  scope :expired, -> { where.not(id: active) }

  def active?
    user_id? &&
    updated_at >= ACTIVITY_THRESHOLD.ago &&
    created_at >= EXPIRATION_THRESHOLD.ago
  end
end
