import { Controller } from "@hotwired/stimulus"
import { supported as webAuthnSupported, get as webAuthnGet } from "@github/webauthn-json";
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static targets = ["error"]

  connect() {
    let supported = true

    if (!webAuthnSupported()) {
      supported = false
    } else {
      PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().then((available) => {
        if (!available) {
          supported = false
        }
      })
    }

    if (!supported) {
      this.element.hidden = true
    }
  }

  async submit(event) {
    const responseText = await event.detail.fetchResponse.responseText
    const credentialOptions = JSON.parse(responseText)

    webAuthnGet({ "publicKey": credentialOptions }).then(async (credential) => {
      const callbackUrl = new URL("/session/passkey_callback", window.location.origin)
      const request = await new FetchRequest('POST', callbackUrl, {
        body: credential,
        responseKind: "turbo-stream"
      }).perform()

      if (request.redirected) {
        const redirect_url = request.response.url.toString()
        Turbo.visit(new URL(redirect_url, document.baseURI))
      }
    }).catch((error) => {
      this.errorTarget.textContent = error
    });
  }
}
