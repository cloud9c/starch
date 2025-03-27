import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class InfiniteScrollController extends Controller {
  static values = { 
    page: { type: Number, default: 1 },
    loading: { type: Boolean, default: false },
    hasNextPage: { type: Boolean, default: true },
    threshold: { type: Number, default: 500 },
    status: { type: String, default: 'inbox' }
  }
  
  connect() {
    this.scrollHandler = () => this.handleScroll()
    window.addEventListener("scroll", this.scrollHandler)
  }
  
  disconnect() {
    window.removeEventListener("scroll", this.scrollHandler)
  }
  
  handleScroll() {
    if (this.loadingValue || !this.hasNextPageValue) return
    
    const { scrollY, innerHeight } = window
    const { scrollHeight } = document.body
    const hasReachedThreshold = scrollY + innerHeight >= scrollHeight - this.thresholdValue
    
    if (hasReachedThreshold) {
      this.loadMore()
    }
  }
  
  async loadMore() {
    console.log("LOADING NOW")
    this.loadingValue = true
    const nextPage = this.pageValue + 1
    
    try {
      const url = this.buildUrl(nextPage)
      const request = await new FetchRequest('GET', url, {
          headers: {
            "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
          }
        }).perform()
      
      if (request.response.status === 204) {
        this.hasNextPageValue = false
      } else if (request.ok) {
        this.pageValue = nextPage
        const html = await request.text
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Error loading more content:", error)
    } finally {
      this.loadingValue = false
    }
  }
  
  buildUrl(page) {
    const url = new URL('/documents', window.location.origin)
    url.searchParams.append('page', page)
    
    if (this.statusValue) {
      url.searchParams.append('status', this.statusValue)
    }
    
    return url.toString()
  }
}