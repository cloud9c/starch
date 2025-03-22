import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = {
    seen: { type: Boolean, default: false },
    id: Number
  }
  
  connect() {
    if (this.seenValue) return
    
    this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
      threshold: 0.8
    })
    
    this.observer.observe(this.element)
  }
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && !this.seenValue) {
        this.seen()
        this.observer.unobserve(this.element)
      }
    })
  }
  
  async seen() {
    const request = new FetchRequest('POST', `/documents/${this.idValue}/seen`)
    const response = await request.perform()
    
    if (response.ok) {
      this.seenValue = true
      this.disconnect()
    }
  }
}