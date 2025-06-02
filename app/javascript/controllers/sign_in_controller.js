import { Controller } from "@hotwired/stimulus"
import { supported as webAuthnSupported, get as webAuthnGet } from "@github/webauthn-json";
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static targets = ["error", "passkeyFields"]

  connect() {
    this.checkSupport()
  }

  async checkSupport() {
    let supported = true
    this.conditionalUISupported = false

    if (!webAuthnSupported()) {
      supported = false
    } else {
      const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()
      if (!available) {
        supported = false
      }

      if (supported && PublicKeyCredential.isConditionalMediationAvailable) {
        this.conditionalUISupported = await PublicKeyCredential.isConditionalMediationAvailable()
      }
    }

    if (!supported) {
      this.passkeyFieldsTarget.hidden = true
    } else if (this.conditionalUISupported) {
      this.startConditionalRequest()
    }
  }

  async startConditionalRequest() {
    try {
      const request = await new FetchRequest('POST', '/session/create_with_passkey', {
        responseKind: "json"
      }).perform()
      
      const credentialOptions = await request.json

      const credential = await webAuthnGet({ 
        mediation: 'conditional',
        publicKey: credentialOptions
      })

      await this.handleCredential(credential)

    } catch (error) {
      console.debug('Conditional UI request failed:', error)
    }
  }

  async submit(event) {
    const responseText = await event.detail.fetchResponse.responseText
    const credentialOptions = JSON.parse(responseText)

    try {
      const credential = await webAuthnGet({ "publicKey": credentialOptions })
      await this.handleCredential(credential)
    } catch (error) {
      this.errorTarget.textContent = "Couldn't use your passkey to login"

      // Restart conditional UI after manual auth fails
      if (this.conditionalUISupported) {
        this.startConditionalRequest()
      }
    }
  }

  async handleCredential(credential) {
    const callbackUrl = new URL("/session/passkey_callback", window.location.origin)
    const request = await new FetchRequest('POST', callbackUrl, {
      body: credential,
      responseKind: "turbo-stream"
    }).perform()

    if (request.redirected) {
      const redirect_url = request.response.url.toString()
      Turbo.visit(new URL(redirect_url, document.baseURI))
    }
  }
}
