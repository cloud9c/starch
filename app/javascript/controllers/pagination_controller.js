import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = { 
    page: { type: Number, default: 1 },
    loading: { type: Boolean, default: false },
    query: { type: String }
  }
  
  connect() {
    this.scrollHandler = () => this.handleScroll()
    window.addEventListener("scroll", this.scrollHandler)
  }
  
  disconnect() {
    window.removeEventListener("scroll", this.scrollHandler)
  }
  
  handleScroll() {
    if (this.loadingValue) return
    
    const { scrollY, innerHeight } = window
    const { scrollHeight } = document.body
    const hasReachedThreshold = scrollY + innerHeight >= scrollHeight - 500
    
    if (hasReachedThreshold) {
      this.loadMore()
    }
  }
  
  async loadMore() {
    this.loadingValue = true
    const nextPage = this.pageValue + 1

    try {
      const url = new URL(window.location.pathname, window.location.origin)
      const searchParams = new URLSearchParams(this.queryValue)
      const currentUrlParams = new URLSearchParams(window.location.search);

      // only override queries defined in queryValue
      currentUrlParams.forEach((value, key) => {
        if (searchParams.has(key)) {
          searchParams.set(key, value)
        }
      });

      searchParams.set("page", nextPage)
      url.search = searchParams.toString()

      const request = await new FetchRequest('GET', url, {
          headers: {
            "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
          }
        }).perform()
    
      if (request.response.status === 204 || request.response.status === 206) {
        this.disconnect()
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
}
