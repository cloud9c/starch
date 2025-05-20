import { Controller } from "@hotwired/stimulus"
import { supported as webAuthnSupported, get as webAuthnCreate } from "@github/webauthn-json";

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
    var [data, status, xhr] = event.detail;
    var credentialOptions = data;
    var credential_nickname = event.target.querySelector("input[name='credential[nickname]']").value;
    var callback_url = `/credentials/callback?credential_nickname=${credential_nickname}`

    function create(callbackUrl, credentialOptions) {
      webAuthnCreate({ "publicKey": credentialOptions }).then(function(credential) {
        callback(callbackUrl, credential);
      }).catch(function(error) {
        // showMessage(error);
      });

      console.log("Creating new public key credential...");
    }
  }
}

