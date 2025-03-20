import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      const searchField = this.element.querySelector("input[type='search']")
      
      if (searchField && searchField.value.trim() !== "") {
        this.element.submit()
      } else {
        event.preventDefault()
      }
    }
  }
}