class VerificationCode < ApplicationRecord
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

  def self.invalidate(user_id, session_id)
    VerificationCode.where(user_id: user_id, session_id: session_id).update_all(used: true)
  end

  def self.find_user(session_id, submitted_code)
    vc = VerificationCode.active.find_by(session_id: session_id, code: submitted_code)
    return nil unless vc

    vc.update(used: true)
    vc.user
  end


  def self.get_code(user_id, session_id, magic_link_token)
    vc = VerificationCode.active.find_by(user_id: user_id, magic_link_token: magic_link_token)

    puts "USER_ID, MAGIC_LINK_TOKEN", user_id, magic_link_token
    puts "VC", vc
    puts "NON_ACTIVE VC", VerificationCode.find_by(user_id: user_id, magic_link_token: magic_link_token)

    return nil unless vc

    vc.code unless vc.session_id == session_id
  end

  def self.sweep
    inactive.delete_all
  end
end
