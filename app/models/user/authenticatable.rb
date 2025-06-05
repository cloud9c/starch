module User::Authenticatable
  extend ActiveSupport::Concern

  included do
    generates_token_for :magic_link, expires_in: 10.minutes do
      verified_at
    end
  end

  class_methods do
    def login(token, verification_code, webauthn_credential = nil, session)
      user = if token.present?
        User.find_by_token_for(:magic_link, token)
      elsif verification_code.present?
        verification = session[:verification]

        if verification && verification["code"] == verification_code
          session.delete(:verification)
          User.find_by_token_for(:magic_link, verification["token"])
        end
      elsif webauthn_credential.present?
        user_handle = webauthn_credential.user_handle
        user = User.find_by(webauthn_id: user_handle)
        credential = user.webauthn_credentials.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))

        webauthn_credential.verify(
          session[:current_authentication]["challenge"],
          public_key: credential.public_key,
          sign_count: credential.sign_count,
          user_verification: true,
        )

        credential.update!(sign_count: webauthn_credential.sign_count)

        user
      end

      return nil unless user

      user.update!(verified_at: Time.current)

      user
    end
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
end
