import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScrollTop = 0
    this.boundScrollHandler = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.boundScrollHandler)
  }
  
  disconnect() {
    window.removeEventListener("scroll", this.boundScrollHandler)
  }
  
  handleScroll(event) {
    const currentScrollTop = window.scrollY || document.documentElement.scrollTop
    
    if (currentScrollTop > this.lastScrollTop) {
      document.body.classList.add("body--scrolled-down")
    } else {
      document.body.classList.remove("body--scrolled-down")
    }
    
    this.lastScrollTop = currentScrollTop
  }
}
