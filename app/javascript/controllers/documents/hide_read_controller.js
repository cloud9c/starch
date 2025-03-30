import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleButton"]

  connect() {
    const hideRead = localStorage.getItem("hideRead") === "true"
    
    if (hideRead) {
      this.element.classList.add("hide-read")
    } else {
      this.element.classList.remove("hide-read")
    }

    this.updateButtonIcon(hideRead)
  }
  
  toggle(event) {
    if (event.target.closest('.document-preview')) {
      return;
    }

    this.element.classList.toggle("hide-read")

    const isHidden = this.element.classList.contains("hide-read")
    localStorage.setItem("hideRead", isHidden)

    this.updateButtonIcon(isHidden)
  }

  updateButtonIcon(isHidden) {
    if (isHidden) {
      this.toggleButtonTarget.classList.remove("btn-icon--caret-down")
      this.toggleButtonTarget.classList.add("btn-icon--caret-up")
      this.toggleButtonTarget.title = "Show"
    } else {
      this.toggleButtonTarget.classList.remove("btn-icon--caret-up")
      this.toggleButtonTarget.classList.add("btn-icon--caret-down")
      this.toggleButtonTarget.title = "Hide"
    }
  }
}