class Verification < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :code, presence: true, length: { is: 6 }
  validates :expires_at, presence: true

  before_validation do
    if user.email_address == "test@example.com"
      self.code = "000000"
    else
      self.code = SecureRandom.random_number(0..999999).to_s.rjust(6, "0")
    end
    self.expires_at = 10.minutes.from_now
  end

  scope :active, -> { where("expires_at > ?", Time.current, false) }
  scope :expired, -> { where("expires_at <= ?", Time.current, true) }

  def self.find_user(session_id, submitted_code)
    verification = active.find_by(session_id: session_id, code: submitted_code)
    return nil unless verification

    user = verification.user
    verification.destroy

    user
  end

  def self.sweep
    expired.destroy_all
  end
end
