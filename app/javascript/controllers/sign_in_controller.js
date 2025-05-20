import { Controller } from "@hotwired/stimulus"
import * as WebAuthn from "credential";
import { supported as webAuthnSupported, create as webAuthnCreate } from "@github/webauthn-json";

export default class extends Controller {
  static targets = ["passkeyFields"]

  connect() {
    let supported = true;

    if (!webAuthnSupported()) {
      supported = false;
    } else {
      PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().then((available) => {
        if (!available) {
          supported = false;
        }
      });
    }

    if (!supported) {
      this.passkeyFieldsTargets.forEach((target) => target.hidden = true);
    }
  }

  create(event) {
    // var [data, status, xhr] = event.detail;
    // console.log(data);
    // var credentialOptions = data;
    // WebAuthn.get(credentialOptions);

    function get(credentialOptions) {
      webAuthnCreate({ "publicKey": credentialOptions }).then(function(credential) {
        callback("/session/callback", credential);
      }).catch(function(error) {
        // showMessage(error);
      });
    }
  }

  error(event) {
    // let response = event.detail[0];
    // let usernameField = new MDCTextField(this.usernameFieldTarget);
    // usernameField.valid = false;
    // usernameField.helperTextContent = response["errors"][0];
  }
}
