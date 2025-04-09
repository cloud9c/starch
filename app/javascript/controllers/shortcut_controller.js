import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    if (event.target !== this.element) return;

    switch (event.key) {
      case "/":
        event.preventDefault();
        document.querySelector("#q").focus();
        break;
      case "h":
      case "H":
        const navMenu = document.querySelector("#navbar__logo-container");
        navMenu.open = !navMenu.open;
        break;
    }
  }
}
