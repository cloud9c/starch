import { Controller } from "@hotwired/stimulus"
import { supported as webAuthnSupported, get as webAuthnCreate } from "@github/webauthn-json";
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static targets = ["message"]

  connect() {
    if (!webAuthnSupported()) {
      this.messageTarget.textContent= "This browser doesn't support WebAuthn API";
    } else {
      PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().then((available) => {
        if (!available) {
          this.messageTarget.textContent = "We couldn't detect a user-verifying platform authenticator";
        }
      });
    }
  }

  create(event) {
    const [data, status, xhr] = event.detail;
    const credentialOptions = data;
    const nickname = event.target.querySelector("input[name='credential[nickname]']").value;

    webAuthnCreate({ "publicKey": credentialOptions }).then((credential) => {
      callbackUrl = new URL("/passkeys/callback", window.location.origin)
      callbackUrl.searchParams.append('nickname', nickname);

      const request = await new FetchRequest('POST', callbackUrl, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: credential
      }).perform()
    }).catch(function(error) {
      console.log(error);
    });
  }
}

