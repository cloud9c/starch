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
    let conditionalUISupported = false

    if (!webAuthnSupported()) {
      supported = false
    } else {
      const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()
      if (!available) {
        supported = false
      }

      // Check for conditional UI support
      if (supported && PublicKeyCredential.isConditionalMediationAvailable) {
        conditionalUISupported = await PublicKeyCredential.isConditionalMediationAvailable()
      }
    }

    if (!supported) {
      this.passkeyFieldsTarget.hidden = true
    } else if (conditionalUISupported) {
      this.startConditionalRequest()
    }
  }

  async startConditionalRequest() {
    try {
      // Use your existing create_with_passkey endpoint
      const request = await new FetchRequest('POST', '/session/create_with_passkey', {
        responseKind: "json"
      }).perform()
      
      const credentialOptions = await request.json

      console.log(credentialOptions)

      // Start conditional mediation request - this will NOT show a popup
      // Instead, it waits silently and shows credentials in autofill dropdown
      const credential = await webAuthnGet({ 
        mediation: 'conditional',
        publicKey: credentialOptions
      })

      // Handle successful authentication (only called if user selects from autofill)
      await this.handleCredential(credential)

    } catch (error) {
      // Conditional UI should fail silently according to spec
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
