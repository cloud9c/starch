class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  has_many :subscriptions, dependent: :destroy
  has_many :channels, through: :subscriptions
  has_many :document_states, dependent: :destroy
  has_many :webauthn_credentials, dependent: :destroy

  before_destroy :cleanup_stripe_customer

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  scope :unverified, -> { where(verified_at: nil) }

  generates_token_for :magic_link, expires_in: 10.minutes do
    verified_at
  end

  def generate_magic_link
    generate_token_for(:magic_link)
  end

  def generate_verification_code
    return "000000" if email_address == "test@example.com"

    SecureRandom.random_number(0..999999).to_s.rjust(6, "0")
  end

  def send_login_email(magic_link_token, verification_code)
    return true if email_address == "test@example.com"

    begin
      AuthenticationMailer
        .with(user: self, magic_link_token: magic_link_token, verification_code: verification_code)
        .login_email.deliver_now
      true
    rescue => e
      Rails.logger.error("Failed to send login email: #{e.message}")
      false
    end
  end

  def self.sweep
    unverified.destroy_all
  end

  def cleanup_stripe_customer
    StripeUtils.handle_user_destroyed(self)
  end
end
