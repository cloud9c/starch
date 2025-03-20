import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "pagination"]
  static values = { 
    page: { type: Number, default: 1 },
    loading: { type: Boolean, default: false },
    hasNextPage: { type: Boolean, default: true },
    status: String
  }
  
  initialize() {
    this.scroll = this.scroll.bind(this)
    this.statusValue = this.element.dataset.status
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
    const bottomPosition = document.body.scrollHeight - 500
    
    if (scrollPosition >= bottomPosition) {
      this.loadMore()
    }
  }
  
  loadMore() {
    this.loadingValue = true
    const nextPage = this.pageValue + 1
    
    let url = `/documents?page=${nextPage}`
    
    if (this.statusValue) {
      url += `&status=${this.statusValue}`
    }
    
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      if (response.status === 204) {
        this.hasNextPageValue = false
        return null
      } else if (response.ok) {
        return response.text()
      }
    })
    .then(html => {
      if (html) {
        this.pageValue = nextPage
        Turbo.renderStreamMessage(html)
      }
    })
    .catch(error => console.error(error))
    .finally(() => {
      this.loadingValue = false
    })
  }
}