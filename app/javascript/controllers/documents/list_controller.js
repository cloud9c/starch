import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = { 
    page: { type: Number, default: 1 },
    loading: { type: Boolean, default: false },
    hasNextPage: { type: Boolean, default: true },
    threshold: { type: Number, default: 500 },
    status: { type: String, default: 'inbox' }
  }
  
  initialize() {
    this.scroll = this.scroll.bind(this)
  }
  
  connect() {
    window.addEventListener("scroll", this.scroll)
  }
  
  disconnect() {
    window.removeEventListener("scroll", this.scroll)
  }
  
  scroll() {
    if (this.loadingValue || !this.hasNextPageValue) return
    
    const scrollPosition = window.scrollY + window.innerHeight
    const bottomPosition = document.body.scrollHeight - this.thresholdValue
    
    if (scrollPosition >= bottomPosition) {
      this.loadMore()
    }
  }
  
  async loadMore() {
    this.loadingValue = true
    const nextPage = this.pageValue + 1
    
    let url = `/documents?page=${nextPage}`
    
    if (this.statusValue) {
      url += `&status=${this.statusValue}`
    }

    const request = new FetchRequest('GET', url, {
    headers: {
      "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
    }
  })
    const response = await request.perform()
  
    if (response.status === 204) {
      this.hasNextPageValue = false
      this.loadingValue = false
    } else if (response.ok) {
      this.pageValue = nextPage
      const html = await response.text
      this.loadingValue = false
      
      Turbo.renderStreamMessage(html)
    }
  }
}