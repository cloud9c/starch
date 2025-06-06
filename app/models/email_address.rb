class EmailAddress < ApplicationRecord
  belongs_to :user

  USERNAME_FORMAT = /\A[a-z0-9._%-]+\z/

  normalizes :username, with: ->(username) { username.strip.downcase }
  before_validation :ensure_username_has_value
  validates :username,
            presence: true,
            uniqueness: true,
            length: { minimum: 3, maximum: 50 },
            format: { with: USERNAME_FORMAT, message: "can only contain letters, numbers, periods, underscores, and hyphens" }

  DOMAIN = "starchmail.com"

  def email_address
    "#{username}@#{DOMAIN}"
  end

  private
    def ensure_username_has_value
      return unless username.blank?

      base = extract_username_from_user_email_address

      if base && !EmailAddress.exists?(username: base)
        self.username = base
      else
        self.username = generate_random_username
      end
    end

    def extract_username_from_user_email_address
      return nil unless user&.email_address.present?

      email_username = user.email_address.split("@").first

      tagless_username = email_username.split("+").first

      if tagless_username.match?(USERNAME_FORMAT) && tagless_username.length >= 3
        tagless_username
      else
        nil
      end
    end

    def generate_random_username
      vowels = %w[a e i o u]
      consonants = %w[k s t n h m y r w]

      syllables = []
      consonants.each do |c|
        vowels.each do |v|
          syllables << "#{c}#{v}"
        end
      end

      loop do 
        base = 3.times.map { syllables.sample }.join
        digits = rand(1000..9999)
        candidate = "#{base}#{digits}"
        
        return candidate unless EmailAddress.exists?(username: candidate)
      end
    end
end
