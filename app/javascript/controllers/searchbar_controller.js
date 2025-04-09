import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  get searchField() {
    return this.element.querySelector("#q");
  }
 
  handleKeydown(event) {
    if (event.key === "Enter") {
      if (this.searchField.value.trim() !== "") {
        this.element.submit()
      } else {
        event.preventDefault()
      }
    }

    switch (event.key) {
      case "Enter":
        if (this.searchField.value.trim() !== "") {
          this.element.submit()
        } else {
          event.preventDefault()
        }
        break;
      case "Escape":
      case "Backspace":
        if (event.key === "Backspace" && !event.metaKey) break;
        this.searchField.value = ""
        break;
    }
  }
}
