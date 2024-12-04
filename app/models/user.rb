class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :verification_codes, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true

  generates_token_for :magic_link, expires_in: 10.minutes

  def send_login_email(magic_link_token)
    AuthenticationMailer.login_email(self, magic_link_token).deliver_now
  end
end
