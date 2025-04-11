import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScrollTop = 0
    this.boundScrollHandler = this.handleScroll.bind(this)
    this.element.addEventListener("scroll", this.boundScrollHandler)
  }
  
  disconnect() {
    this.element.removeEventListener("scroll", this.boundScrollHandler)
  }
  
  handleScroll(event) {
    const currentScrollTop = this.element.scrollTop
    
    if (currentScrollTop > this.lastScrollTop) {
      // Scrolling down
      this.element.classList.add("sheet--scrolled-down")
    } else {
      // Scrolling up
      this.element.classList.remove("sheet--scrolled-down")
    }
    
    // Update last scroll position
    this.lastScrollTop = currentScrollTop
  }
}
