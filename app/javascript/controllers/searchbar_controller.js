import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.addEventListener('keydown', (e) => {
      if (e.key === '/' && !this.isTypingInInput(e)) {
        console.log("ehre")
        e.preventDefault()
        this.element.querySelector('input[type="search"]').focus()
      }
    })
  }

  isTypingInInput(e) {
    return ['input', 'textarea'].includes(e.target.tagName.toLowerCase())
  }
}