import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["document"]
  
  updateDocument(event) {
    const selectedButton = event.currentTarget

    this.documentTargets.forEach(button => {
      button.setAttribute("data-checked", button === selectedButton ? "true" : "false")
    })
  }
}
