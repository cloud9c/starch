import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: { type: String, default: "/session/new" },
    redirected: { type: Boolean, default: false }
  }
  
  connect() {
    if (this.urlValue !== undefined && this.redirectedValue === false) {
      this.redirectedValue = true
      Turbo.visit(this.urlValue)
    }
  }
}
