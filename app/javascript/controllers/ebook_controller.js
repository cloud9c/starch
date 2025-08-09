import { Controller } from "@hotwired/stimulus"
import "/foliate-js/view.js"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = {
    url: String,
    cfi: String
  }

  static targets = ["progressSlider", "content", "progressStepList", "header", "footer", "section", "overlay", "flow"]

  async connect() {
    this.view = document.createElement("foliate-view")
    const book = this.view
    this.contentTarget.prepend(book)

    document.addEventListener("keydown", this.onKeydown.bind(this))
    book.addEventListener("load", this.onLoad.bind(this))
    book.addEventListener("relocate", this.onRelocate.bind(this))
    book.addEventListener("mousedown", this.onMouseDown.bind(this))
    book.addEventListener("mouseup", this.onMouseUp.bind(this))

    await book.open(this.urlValue)

    this.setStyles()

    if (this.cfiValue) {
      await book.goTo(this.cfiValue)
    } else {
      await book.renderer.next()
    }

    this.setupControls()
  }

  setStyles() {
    const book = this.view
    book.renderer.setStyles?.(getCSS({
        spacing: 1.4,
        justify: true,
        hyphenate: true,
    }))
    book.renderer.setAttribute("margin", "16px");
    book.renderer.setAttribute("gap", "2%");
    book.renderer.setAttribute("max-column-count", "2");

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
      this.setStyles()
    });

    // Flow toggle
    if (this.hasFlowTarget) {
      this.flowTarget.addEventListener("change", (e) => {
        book.renderer.setAttribute("flow", e.target.checked ? "paginated" : "scrolled")
      })
    }
  }

  showControls() {
    const sections = this.sectionTargets
    sections.forEach(section => {
      section.style.opacity = '1'
    })
  }

  hideControls() {
    const sections = this.sectionTargets
    sections.forEach(section => {
      section.style.opacity = '0'
    })
  }

  onLoad({ detail: { doc, index } }) {
    doc.addEventListener("keydown", this.onKeydown.bind(this))
    doc.addEventListener("mousedown", this.onMouseDown.bind(this))
    doc.addEventListener("mouseup", this.onMouseUp.bind(this))
  }

  updateProgressSliderTrack(target) {
    const value = (target.value-target.min)/(target.max-target.min)*100
    target.style.background = 'linear-gradient(to right, var(--color-primary) 0%, var(--color-primary) ' + value + '%, #fff ' + value + '%, white 100%)'
  }

  setupControls() {
    // Toggle header/footer visibility on hover
    const sections = this.sectionTargets

    sections.forEach(section => {
      section.addEventListener('mouseenter', this.showControls.bind(this))
      section.addEventListener('mouseleave', this.hideControls.bind(this))
    })

    // Progress slider
    const progressSlider = this.progressSliderTarget
    progressSlider.dir = this.view.dir

    progressSlider.addEventListener('input', e => {
      this.view.goToFraction(parseFloat(e.target.value))
      this.updateProgressSliderTrack(e.target)
    })

    progressSlider.addEventListener('keydown', e => {
      if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
        e.preventDefault()
        e.stopPropagation()
      }
    })
    progressSlider.addEventListener("input",  function() {

    });

    // Progress step list
    // const stepList = this.progressStepListTarget
    // const sectionFractions = this.view.getSectionFractions().filter(fraction => {
    //   return fraction >= 0 && fraction <= 1
    // })
    //
    // for (const fraction of sectionFractions) {
    //   const option = document.createElement("option")
    //   option.value = fraction
    //   stepList.append(option)
    //
    //   const visualOption = document.createElement("div")
    //   visualOption.style.setProperty("--position", `${fraction * 100}%`)
    //   stepList.append(visualOption)
    // }
  }

  onRelocate({ detail: { fraction, cfi, location } }) {
    clearTimeout(this.progressTimeout)

    this.progressSliderTarget.value = fraction
    this.updateProgressSliderTrack(this.progressSliderTarget)

    this.progressTimeout = setTimeout(() => {
      const isDoublePage = window.innerWidth > window.innerHeight
      const isLastPage = isDoublePage ?
        (location?.next === location?.total - 1) :
        (location?.next === location?.total)

      const adjustedFraction = isLastPage ? 1 : fraction || 0
      this.updateProgress(adjustedFraction, cfi)
    }, 500)
  }

  onMouseDown(e) {
    this.mouseStart = { x: e.clientX, y: e.clientY }
  }

  onMouseUp(e) {
    if (this.clickTimeout) {
      clearTimeout(this.clickTimeout)
      this.clickTimeout = null
      return
    }

    const deltaX = Math.abs(e.clientX - this.mouseStart.x)
    const deltaY = Math.abs(e.clientY - this.mouseStart.y)
    if (deltaX > 5 || deltaY > 5) return

    this.clickTimeout = setTimeout(() => {
      this.handleClick(e)
      this.clickTimeout = null
    }, 300)
  }

  handleClick(e) {

    const percentageX = e.screenX / window.innerWidth

    if (percentageX > 0.80) {
      this.view.goLeft()
    } else if (percentageX < 0.20) {
      this.view.goRight()
    } else {
      this.element.toggleAttribute('data-paused')
    }
  }

  overlayClick(e) {
    const side = e.currentTarget.dataset.side
 
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
    }

    body {
      background-color: ${getCSSVariable("--bg-primary")} !important;
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
