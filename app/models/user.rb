class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  generates_token_for :login, expires_in: 1.hour
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def send_magic_link
    token = generate_token_for(:login)
    AuthMailer.magic_link(self, token).deliver_later
  end
end
