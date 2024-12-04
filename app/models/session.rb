class Session < ApplicationRecord
  belongs_to :user, optional: true

  def expired?
    updated_at < 24.hours.ago || created_at < 2.weeks.ago
  end

  def self.sweep
    where(expired: true).delete_all
  end
end
