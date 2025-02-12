class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :verifications, dependent: :destroy

  has_many :folders, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :channels, through: :subscriptions
  has_many :document_user_states, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true

  scope :unverified, -> { where(verified_at: nil) }

  generates_token_for :magic_link, expires_in: 10.minutes do
    verified_at
  end

  def send_login_email(magic_link_token, verification_code)
    AuthenticationMailer.login_email(self, magic_link_token, verification_code).deliver_now
  end

  def self.sweep
    unverified.destroy_all
  end
end
