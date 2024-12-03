class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  generates_token_for :magic_link, expires_in: 10.minutes
  generates_token_for :verification_code, expires_in: 10.minutes do
    code = SecureRandom.random_number(1..999_999).to_s.rjust(6, '0')
    { verification_code: code }
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  def send_login_email
    magic_link = generate_token_for(:magic_link)
    
    generate_token_for(:verification_code)
    verification_code = User.token_definitions[:verification_code].payload_for(self)[1]["verification_code"]

    AuthenticationMailer.login_email(self, magic_link, verification_code).deliver_later
  end
end
