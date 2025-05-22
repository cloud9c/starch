class PasskeysController < ApplicationController
  before_action :ensure_webauthn_id, only: [ :create ]

  def create
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: Current.user.webauthn_id,
        name: Current.user.email_address
      },
      exclude: Current.user.webauthn_credentials.pluck(:external_id),
      authenticator_selection: { user_verification: "required" }
    )

    session[:current_registration] = {
      challenge: create_options.challenge,
      user_attributes: Current.user.attributes
    }

    render json: create_options
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_create(params)

    Rails.logger.debug params.inspect

    begin
      webauthn_credential.verify(session[:current_registration]["challenge"], user_verification: true)

      credential = Current.user.webauthn_credentials.find_or_initialize_by(
        external_id: Base64.strict_encode64(webauthn_credential.raw_id),
      )

      if credential.update(
        nickname: params[:nickname],
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )
        render plain: "OK", status: :ok
      else
        render plain: "Couldn't add your Security Key", status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      render plain: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:current_registration)
    end
  end

  def destroy
    Current.user.webauthn_credentials.destroy(params[:id])
  end

  private

  def ensure_webauthn_id
    return if Current.user.webauthn_id.present?

    Current.user.update(webauthn_id: WebAuthn.generate_user_id)
  end
end
