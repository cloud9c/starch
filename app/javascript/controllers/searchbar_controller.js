import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
    this.form = this.element.closest("form")
    
    if (this.form) {
      this.form.addEventListener("turbo:submit-end", this.updateUrl.bind(this))
    }
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
    
    if (this.form) {
      this.form.removeEventListener("turbo:submit-end", this.updateUrl.bind(this))
    }
  }
 
  handleKeydown(event) {
    switch (event.key) {
      case "Enter":
        if (this.element.value.trim() !== "") {
          this.form.requestSubmit()
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

  updateUrl() {
    const searchValue = this.element.value.trim()
    if (searchValue !== "") {
      const url = new URL(window.location)
      url.searchParams.set('q', searchValue)
      
      window.history.replaceState({ q: searchValue }, '', url.toString())
    }
  }
}
