class Session < ApplicationRecord
  belongs_to :user, optional: true
  has_many :verifications, dependent: :destroy

  scope :expired, -> { where("updated_at < ? OR created_at < ?", 24.hours.ago, 2.weeks.ago) }

  def self.sweep
    expired.destroy_all
  end
end
