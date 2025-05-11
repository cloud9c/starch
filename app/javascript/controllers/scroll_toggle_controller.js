import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScrollTop = 0
    this.boundScrollHandler = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.boundScrollHandler)
    this.handleScroll()
  }
  
  disconnect() {
    window.removeEventListener("scroll", this.boundScrollHandler)
  }
  
  handleScroll() {
    const currentScrollTop = window.scrollY || document.documentElement.scrollTop
    
    // Handle body--scrolled class
    if (currentScrollTop > 0) {
      document.body.classList.add("body--scrolled")
    } else {
      document.body.classList.remove("body--scrolled")
    }
    
    // Handle body--scrolled-down class
    if (currentScrollTop > this.lastScrollTop) {
      document.body.classList.add("body--scrolled-down")
    } else {
      document.body.classList.remove("body--scrolled-down")
    }
    
    this.lastScrollTop = currentScrollTop
  }
}
