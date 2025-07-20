import { Controller } from "@hotwired/stimulus"
import "/foliate-js/view.js"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = {
    url: String,
    cfi: String
  }

  async connect() {
    this.view = document.createElement('foliate-view')
    this.element.appendChild(this.view)

    document.addEventListener('keydown', this.handleKeydown.bind(this))

    this.view.addEventListener('load', this.onLoad.bind(this))
    this.view.addEventListener('relocate', this.handleRelocate.bind(this))
    this.view.addEventListener("create-overlayer", this.createOverlayer.bind(this))

    await this.view.open(this.urlValue)

    if (this.cfiValue) {
      await this.view.goTo(this.cfiValue)
    } else {
      await this.view.renderer.next()
    }
  }

  onLoad({ detail: { doc, index } }) {
    doc.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  handleRelocate({ detail: { fraction, cfi, location } }) {
    clearTimeout(this.progressTimeout)

    this.progressTimeout = setTimeout(() => {
      const isDoublePage = window.innerWidth > window.innerHeight
      const isLastPage = isDoublePage ? 
        (location?.next === location?.total - 1) :
        (location?.next === location?.total)

      const adjustedFraction = isLastPage ? 1 : fraction || 0
      this.updateProgress(adjustedFraction, cfi)
    }, 500)
  }

  async updateProgress(progress, progressIdentifier) {
    await patch(window.location.href, {
      body: JSON.stringify({
        document: {
          progress: progress,
          progress_identifier: progressIdentifier
        }
      })
    })
  }

  createOverlayer({ detail: { doc, index, attach } }) {

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
