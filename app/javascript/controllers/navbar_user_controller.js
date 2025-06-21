import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "navbar-user"

  connect() {
    super.connect()

    const element = this.bridgeElement
    const hue = element.bridgeAttribute("user-hue")
    const title = element.bridgeAttribute("user-title")

    this.send("connect", {hue, title}, () => {
      Turbo.visit("/user")
    })
 }
}
