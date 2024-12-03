import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["emailForm", "verificationForm"]

  connect() {
    this.emailFormTarget.addEventListener("submit", this.showVerification.bind(this))
  }

showVerification(event) {
  // Let form submit first
  const formData = new FormData(event.target)
  fetch(event.target.action, {
    method: 'POST',
    body: formData
  })
  
  this.emailFormTarget.style.display = "none"
  this.verificationFormTarget.style.display = "block"
  
  event.preventDefault() // Prevent default at end to avoid double submit
}
}