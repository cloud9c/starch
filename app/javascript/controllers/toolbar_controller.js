import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["documentState"]
  
  updateDocumentState(event) {
    const selectedButton = event.currentTarget
    
    this.documentStateTargets.forEach(button => {
      button.setAttribute("data-checked", button === selectedButton ? "true" : "false")
    })
  }
}
