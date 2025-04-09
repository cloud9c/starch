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
      case "1":
        redirect();
        break;
      case "2":
        redirect("later");
        break;
      case "3":
        redirect("feed");
        break;
      case "4":
        redirect("subscriptions");
        break;
      case "5":
        redirect("search");
        break;
      case "6":
        redirect("archive");
        break;
    }
  }
}

function redirect(path="", baseUrl = window.location.origin) {
  const formattedBaseUrl = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  
  const redirectUrl = `${formattedBaseUrl}/${path}`;
  window.location.href = redirectUrl;
}
