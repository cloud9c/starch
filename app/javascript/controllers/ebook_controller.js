import { Controller } from "@hotwired/stimulus"
import "/foliate-js/view.js"

export default class extends Controller {
  static values = { url: String }

  async connect() {
    this.view = document.createElement('foliate-view')
    this.element.appendChild(this.view)

    document.addEventListener('keydown', this.handleKeydown.bind(this))

    this.view.addEventListener('relocate', this.handleRelocate.bind(this))
    this.view.addEventListener('load', this.onLoad.bind(this))
    this.view.addEventListener('click', this.handleClick.bind(this))

    await this.view.open(this.urlValue)
    await this.view.renderer.next()
  }

  onLoad({ detail: { doc } }) {
    doc.addEventListener('keydown', this.handleKeydown.bind(this))
    doc.addEventListener('click', this.handleClick.bind(this))
  }

  handleRelocate(event) {

  }

  handleClick(event) {
    const NAVIGATION_THRESHOLD = 0.25
    const viewportWidth = window.innerWidth
    const clickX = event.clientX
    const clickPercentage = clickX / viewportWidth

    if (clickPercentage <= NAVIGATION_THRESHOLD) {
      event.preventDefault();
      event.stopPropagation();
      this.view.goLeft()
    } else if (clickPercentage >= 1 - NAVIGATION_THRESHOLD) {
      event.preventDefault();
      event.stopPropagation();
      this.view.goRight()
    }
  }

  handleKeydown(event) {
    switch(event.key) {
      case "ArrowLeft":
        this.view.goLeft()
        break;
      case "ArrowRight":
        this.view.goRight()
        break;
    }
  }

  disconnect() {
    if (this.view) {
      this.view.remove()
    }
  }
}
