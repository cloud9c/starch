class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :verifications, dependent: :destroy

  has_many :folders, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :channels, through: :subscriptions
  has_many :document_states, dependent: :destroy

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

  def generate_verification
    Verification.create!(user_id: id, session_id: Current.session.id)
  end

  def send_login_email(magic_link_token, verification_code)
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

  def verify
    update!(verified_at: Time.current) if verified_at.nil?
  end

  def self.find_user_by_params(token, verification_code)
    if token.present?
      User.find_by_token_for(:magic_link, token)
    elsif verification_code.present?
      Verification.find_user(Current.session.id, verification_code)
    end
  end

  def self.sweep
    unverified.destroy_all
  end
end
