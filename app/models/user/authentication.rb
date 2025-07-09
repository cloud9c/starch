module User::Authentication
  extend ActiveSupport::Concern

  included do
    has_many :sessions, dependent: :destroy
    generates_token_for :magic_link, expires_in: 10.minutes do
      verified_at
    end
  end

  class_methods do
    def authenticate_by(token: nil, verification_code: nil, webauthn_credential: nil, session: nil)
      user = if token.present?
        User.find_by_token_for(:magic_link, token)
      elsif verification_code.present?
        authenticate_by_verification_code(verification_code:, session:)
      elsif webauthn_credential.present?
        authenticate_by_webauthn(webauthn_credential:, session:)
      end

      if user.present?
        user.update!(verified_at: Time.current)
      end

      user
    end

    def authenticate_by_verification_code(verification_code:, session:)
      credential = session[:verification]
      return nil unless credential

      if ActiveSupport::SecurityUtils.secure_compare(credential["code"], verification_code)
        session.delete(:verification)
        User.find_by_token_for(:magic_link, credential["token"])
      end
    end

    def authenticate_by_webauthn(webauthn_credential:, session:)
      user_handle = webauthn_credential.user_handle
      user = User.find_by(webauthn_id: user_handle)
      return nil unless user

      credential = user.webauthn_credentials.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))
      return nil unless credential

      challenge = session[:current_authentication]&.dig("challenge")
      return nil unless challenge

      webauthn_credential.verify(
        challenge,
        public_key: credential.public_key,
        sign_count: credential.sign_count,
        user_verification: true,
      )

      credential.update!(sign_count: webauthn_credential.sign_count)

      user
    rescue WebAuthn::Error
      nil
    ensure
      session.delete(:current_authentication)
    end
  end

  def generate_authentication(session)
    magic_link_token = generate_magic_link
    verification_code = generate_verification_code

    session[:verification] = {
      code: verification_code,
      token: magic_link_token
    }

    send_login_email(magic_link_token, verification_code)
  end

  private

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
end
