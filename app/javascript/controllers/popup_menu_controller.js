import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  connect() {
    this.boundClickHandler = this.handleClick.bind(this)
    this.boundKeydownHandler = this.handleKeydown.bind(this)
    
    window.addEventListener("click", this.boundClickHandler)
    window.addEventListener("keydown", this.boundKeydownHandler)
  }
  
  disconnect() {
    window.removeEventListener("click", this.boundClickHandler)
    window.removeEventListener("keydown", this.boundKeydownHandler)
  }
  
  handleClick(event) {
    if(!this.element.contains(event.target)){
      this.element.removeAttribute('open')
    }
  }
  
  handleKeydown(event) {
    if(event.key === "Escape" && this.element.hasAttribute('open')) {
      this.element.removeAttribute('open')
    }
  }
}
