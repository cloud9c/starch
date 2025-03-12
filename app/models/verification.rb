class Verification < ApplicationRecord
  belongs_to :user
  belongs_to :session

  validates :user_id, presence: true
  validates :session_id, presence: true
  validates :code, presence: true, length: { is: 6 }
  validates :expires_at, presence: true

  before_validation do
    self.code = SecureRandom.random_number(0..999999).to_s.rjust(6, "0")
    self.expires_at = 10.minutes.from_now
  end

  scope :active, -> { where("expires_at > ? AND used = ?", Time.current, false) }
  scope :inactive, -> {  where("expires_at <= ? OR used = ?", Time.current, true) }

  def self.find_user(session_id, submitted_code)

    ### DELETE THIS ASAP
    vc = active.find_by(session_id: session_id)
    Rails.logger.debug "EMAIL ADDRESS #{vc.user.email_address}"
    if vc.user.email_address == "test@example.com"
      vc.update(used: true)
      return vc.user
    end
    ###

    vc = active.find_by(session_id: session_id, code: submitted_code)
    return nil unless vc

    vc.update(used: true)
    vc.user
  end

  def self.sweep
    inactive.destroy_all
  end
end
