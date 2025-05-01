import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  connect() {
    this.handleFocus();
    
    window.addEventListener('focus', this.handleFocus.bind(this))
  }
  
  disconnect() {
    window.removeEventListener('focus', this.handleFocus.bind(this))
  }
  
  handleFocus() {
    Turbo.visit("/session/new")
  }
}
