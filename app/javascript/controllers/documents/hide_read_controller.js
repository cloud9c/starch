import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const openRead = localStorage.getItem("openRead") === "true";

    this.element.open = openRead;
    this.element.addEventListener("toggle", this.updateStorage.bind(this));
    this.element.addEventListener("click", () => {
      if (event.target !== this.element) return;

       event.preventDefault()
      this.element.open = !this.element.open;
    })
  }
  
  updateStorage() {
    localStorage.setItem("openRead", this.element.open);
  }
}
