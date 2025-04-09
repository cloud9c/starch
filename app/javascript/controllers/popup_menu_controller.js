import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundClickHandler = this.handleClick.bind(this)
    window.addEventListener("click", this.boundClickHandler)
  }
  
  disconnect() {
    window.removeEventListener("click", this.boundClickHandler)
  }

  handleClick(event) {
    if(!this.element.contains(event.target)){
      this.element.removeAttribute('open')
    }
  }
}
