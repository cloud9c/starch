import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundScrollHandler = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.boundScrollHandler)
    // Check initial scroll position when connecting
    this.handleScroll()
  }
  
  disconnect() {
    window.removeEventListener("scroll", this.boundScrollHandler)
  }
  
  handleScroll() {
    const currentScrollTop = window.scrollY || document.documentElement.scrollTop
    
    if (currentScrollTop > 0) {
      document.body.classList.add("body--scrolled")
    } else {
      document.body.classList.remove("body--scrolled")
    }
  }
}
