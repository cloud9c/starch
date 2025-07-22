import { Controller } from "@hotwired/stimulus"
import "/foliate-js/view.js"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = {
    url: String,
    cfi: String
  }

  static targets = ["progressSlider", "content", "progressStepList", "header", "footer", "section", "overlay"]

  async connect() {
    this.view = document.createElement("foliate-view")
    const book = this.view
    this.contentTarget.appendChild(book)

    document.addEventListener("keydown", this.onKeydown.bind(this))
    this.view.addEventListener("load", this.onLoad.bind(this))
    this.view.addEventListener("relocate", this.onRelocate.bind(this))
    this.overlayTargets.forEach(overlay => overlay.addEventListener("click", this.onClick.bind(this)))

    await book.open(this.urlValue)

    book.renderer.setStyles?.(getCSS({
        spacing: 1.4,
        justify: true,
        hyphenate: true,
    }))

    this.setupControls()

    if (this.cfiValue) {
      await book.goTo(this.cfiValue)
    } else {
      await book.renderer.next()
    }
  }

  setupControls() {
    // Toggle header/footer visibility on hover
    let hideTimeout
    const sections = this.sectionTargets

    const showControls = () => {
      clearTimeout(hideTimeout)
      sections.forEach(section => {
        section.style.opacity = '1'
        section.style.transition = 'opacity 0.1s linear'
      })
    }

    const hideControls = () => {
      sections.forEach(section => {
        section.style.opacity = '0'
        section.style.transition = 'opacity 0.1s linear'
      })
    }

    sections.forEach(section => {
      section.addEventListener('mouseenter', showControls)
      section.addEventListener('mouseleave', hideControls)
    })

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
    const side = event.currentTarget.dataset.side
    console.log(`Clicked ${side} overlay`)
 
    if (side === 'left') {
      this.view.goLeft()
    } else if (side === 'right') {
      this.view.goRight()
    }
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

const getCSSVariable = (variable) => getComputedStyle(document.documentElement).getPropertyValue(variable).trim()

const getCSS = ({ spacing, justify, hyphenate }) => {
  return `
    @namespace epub "http://www.idpf.org/2007/ops";
    html {
      color-scheme: light dark;
      background: ${getCSSVariable("--bg-primary")} !important;
    }
    * {
      color: ${getCSSVariable("--color-text")} !important;
    }

    /* Link colors */
    a, a:visited, a:link {
      color: ${getCSSVariable("--color-link")} !important;
    }

    /* Border colors */
    hr, table, th, td {
      border-color: ${getCSSVariable("--color-border")} !important;
    }

    /* Code/Pre blocks */
    code, pre {
      background: ${getCSSVariable("--bg-secondary")} !important;
      color: ${getCSSVariable("--color-text")} !important;
      border: 1px solid ${getCSSVariable("--color-border")} !important;
    }

    /* Tables */
    table {
      background: ${getCSSVariable("--bg-primary")} !important;
    }

    th {
      background: ${getCSSVariable("--bg-secondary")} !important;
    }

    p, li, blockquote, dd {
      line-height: ${spacing};
      text-align: ${justify ? 'justify' : 'start'};
      -webkit-hyphens: ${hyphenate ? 'auto' : 'manual'};
      hyphens: ${hyphenate ? 'auto' : 'manual'};
      -webkit-hyphenate-limit-before: 3;
      -webkit-hyphenate-limit-after: 2;
      -webkit-hyphenate-limit-lines: 2;
      hanging-punctuation: allow-end last;
      widows: 2;
    }
    /* prevent the above from overriding the align attribute */
    [align="left"] { text-align: left; }
    [align="right"] { text-align: right; }
    [align="center"] { text-align: center; }
    [align="justify"] { text-align: justify; }
    pre {
      white-space: pre-wrap !important;
    }
    aside[epub|type~="endnote"],
    aside[epub|type~="footnote"],
    aside[epub|type~="note"],
    aside[epub|type~="rearnote"] {
      display: none;
    }
  `
}
