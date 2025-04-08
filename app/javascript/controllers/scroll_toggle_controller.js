import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundScrollHandler = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.boundScrollHandler)
    
    this.handleScroll()
  }
  
  disconnect() {
    window.removeEventListener("scroll", this.boundScrollHandler)
  }
  
  handleScroll() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop
    
    if (scrollTop > 0) {
      this.element.classList.add("navbar--scrolled")
    } else {
      this.element.classList.remove("navbar--scrolled")
    }
  }
}
