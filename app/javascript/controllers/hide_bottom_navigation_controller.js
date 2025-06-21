import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "hide-bottom-navigation"

  connect() {
    super.connect()
    this.send("connect", {}, () => {
    })
  }
}
