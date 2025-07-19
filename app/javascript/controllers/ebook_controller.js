import { Controller } from "@hotwired/stimulus"
import "foliate-view"

export default class extends Controller {
  static values = { url: String }

  async connect() {
    this.view = document.createElement('foliate-view')
    this.element.appendChild(this.view)

    this.view.addEventListener('relocate', (e) => {
    })

    await this.view.open(this.urlValue)
    await this.view.renderer.next()

    this.element.addEventListener('click', this.handleEdgeClick.bind(this))
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  handleEdgeClick(event) {
    const rect = this.view.getBoundingClientRect()
    const clickX = event.clientX - rect.left
    const width = rect.width
    const edgeThreshold = width * 0.4

    if (clickX < edgeThreshold) {
      this.view.goLeft()
    } else if (clickX > width - edgeThreshold) {
      this.view.goRight()
    }
  }

  handleKeydown(event) {
    if (event.key === 'ArrowLeft') {
      this.view.goLeft()
    } else if (event.key === 'ArrowRight') {
      this.view.goRight()
    }
  }

  disconnect() {
    if (this.view) {
      this.view.remove()
    }
  }
}
