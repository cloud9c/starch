import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

 
  handleKeydown(event) {
    switch (event.key) {
      case "Enter":
        if (this.element.value.trim() !== "") {
          this.element.closest("form").submit()
        } else {
          event.preventDefault()
        }
        break;
      case "Escape":
        this.element.blur();
        break;
      case "Backspace":
        if (event.key === "Backspace" && !event.metaKey) break;
        this.element.value = ""
        break;
    }
  }
}
