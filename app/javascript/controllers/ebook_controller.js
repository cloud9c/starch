import { Controller } from "@hotwired/stimulus"
import "/foliate-js/view.js"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = {
    url: String,
    cfi: String
  }

  static targets = ["progressSlider", "content", "progressStepList", "header", "footer"]

  async connect() {
    this.view = document.createElement("foliate-view")
    const book = this.view
    this.contentTarget.appendChild(book)

    document.addEventListener("keydown", this.onKeydown.bind(this))
    this.view.addEventListener("click", this.onClick.bind(this))
    this.view.addEventListener("load", this.onLoad.bind(this))
    this.view.addEventListener("relocate", this.onRelocate.bind(this))

    await book.open(this.urlValue)
    this.setupControls()

    if (this.cfiValue) {
      await book.goTo(this.cfiValue)
    } else {
      await book.renderer.next()
    }
  }

  setupControls() {
    let hideTimeout
    const header = this.headerTarget
    const footer = this.footerTarget

    const showControls = () => {
      console.log("here")
      clearTimeout(hideTimeout)
      header.style.opacity = '1'
      footer.style.opacity = '1'
      header.style.transition = 'opacity 0.1s linear'
      footer.style.transition = 'opacity 0.1s linear'
    }

    const hideControls = () => {
      header.style.opacity = '0'
      footer.style.opacity = '0'
      header.style.transition = 'opacity 0.1s linear'
      footer.style.transition = 'opacity 0.1s linear'
    }

    // Add event listeners
    header.addEventListener('mouseenter', showControls)
    header.addEventListener('mouseleave', hideControls)
    footer.addEventListener('mouseenter', showControls)
    footer.addEventListener('mouseleave', hideControls)

    // Progress slider
    const progressSlider = this.progressSliderTarget
    progressSlider.dir = this.view.dir
    progressSlider.addEventListener('input', e =>
        this.view.goToFraction(parseFloat(e.target.value)))

    progressSlider.addEventListener('keydown', e => {
      if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
        e.preventDefault()
        e.stopPropagation()
      }
    })

    // Progress step list
    const stepList = this.progressStepListTarget
    const sectionFractions = this.view.getSectionFractions().filter(fraction => {
      return fraction >= 0 && fraction <= 1
    })

    for (const fraction of sectionFractions) {
      const option = document.createElement("option")
      option.value = fraction
      stepList.append(option)

      const visualOption = document.createElement("div")
      visualOption.style.setProperty("--position", `${fraction * 100}%`)
      stepList.append(visualOption)
    }
  }

  onLoad({ detail: { doc, index } }) {
    doc.addEventListener("keydown", this.onKeydown.bind(this))
  }

  onRelocate({ detail: { fraction, cfi, location } }) {
    clearTimeout(this.progressTimeout)

    this.progressSliderTarget.value = fraction

    this.progressTimeout = setTimeout(() => {
      const isDoublePage = window.innerWidth > window.innerHeight
      const isLastPage = isDoublePage ? 
        (location?.next === location?.total - 1) :
        (location?.next === location?.total)

      const adjustedFraction = isLastPage ? 1 : fraction || 0
      this.updateProgress(adjustedFraction, cfi)
    }, 500)
  }

  onClick(event) {
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

  onKeydown(event) {
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
