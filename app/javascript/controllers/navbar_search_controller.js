import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "navbar-search"

  connect() {
    super.connect()

    const element = this.bridgeElement
    const placeholder = element.bridgeAttribute("placeholder")

    this.send("connect", {placeholder}, (response) => {
      const { data } = response
      if (data.query) {
        const searchUrl = `/search?q=${encodeURIComponent(data.query)}`
        Turbo.visit(searchUrl)
      }
    })
 }
}
