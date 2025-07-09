class User < ApplicationRecord
  include Authentication, Billable, Emailable

  has_many :subscriptions, dependent: :destroy
  has_many :feeds, through: :subscriptions
  has_many :documents, dependent: :destroy
  has_many :webauthn_credentials, dependent: :destroy

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }
  validates :email_address,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  scope :unverified, -> { where(verified_at: nil) }
end
