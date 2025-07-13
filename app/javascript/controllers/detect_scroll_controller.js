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
    const scrollHeight = document.documentElement.scrollHeight
    const clientHeight = document.documentElement.clientHeight

    if (currentScrollTop > 0) {
      document.body.classList.add("body--scrolled")
    } else {
      document.body.classList.remove("body--scrolled")
    }

    if (currentScrollTop > this.lastScrollTop) {
      document.body.classList.add("body--scrolled-down")
      document.body.classList.remove("body--scrolled-up")
    } else if (currentScrollTop < this.lastScrollTop) {
      document.body.classList.remove("body--scrolled-down")
      document.body.classList.add("body--scrolled-up")
    }

    if (Math.abs(scrollHeight - clientHeight - currentScrollTop) < 1) {
      document.body.classList.add("body--scrolled-bottom")
    } else {
      document.body.classList.remove("body--scrolled-bottom")
    }

    this.lastScrollTop = currentScrollTop
  }
}
