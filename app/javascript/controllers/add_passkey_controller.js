import { Controller } from "@hotwired/stimulus"
import { supported as webAuthnSupported, create as webAuthnCreate } from "@github/webauthn-json";
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static targets = ["error", "fieldset"]

  connect() {
    if (!webAuthnSupported()) {
      this.fieldsetTarget.disabled = true;
      this.errorTarget.textContent = "This browser doesn't support WebAuthn API";
    } else {
      PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().then((available) => {
        if (!available) {
          this.fieldsetTarget.disabled = true;
          this.errorTarget.textContent = "We couldn't detect a user-verifying platform authenticator"
        }
      });
    }
  }

  async submit(event) {
    const nickname = event.detail.formSubmission.body.get("passkey[nickname]")
    const credentialOptions = JSON.parse(await event.detail.fetchResponse.responseText)

    webAuthnCreate({ "publicKey": credentialOptions }).then(async (credential) => {
      const callbackUrl = new URL("/user/security/passkeys/callback", window.location.origin)
      callbackUrl.searchParams.append('nickname', nickname)

      const request = await new FetchRequest('POST', callbackUrl, {
        responseKind: "turbo-stream",
        body: credential
      }).perform()
    }).catch((error) => {
      this.errorTarget.textContent = error
    })
  }
}

