import { Controller } from "@hotwired/stimulus"
import { patch } from '@rails/request.js'

const UPDATE_RATE_LIMIT = 3000
const DEBOUNCE = 500

export default class extends Controller {
  static values = {
    progress: Number,
    lastUpdated: Number,
  }

  connect() {
    this.abortController = new AbortController()
    this.connectListeners()

    const iframe = this.element.querySelector('.document__container--iframe')
    if (iframe) {
      const observer = new ResizeObserver(() => {
        if (iframe.offsetHeight > 0) {
          this.scrollToProgress()
          observer.disconnect()
        }
      })
      observer.observe(iframe)
    } else {
      this.scrollToProgress()
    }
  }

  disconnect() {
    clearTimeout(this.rateLimitTimeout)
    this.abortController.abort()
  }

  syncProgress() {
    const oldProgress = this.progressValue
    const rect = this.element.getBoundingClientRect()
    const viewportHeight = window.innerHeight

    if (this.isSmallElement(rect.height, viewportHeight)) {
      this.progressValue = rect.bottom > 0 && rect.top < viewportHeight ? 1 : 0
    } else {
      this.progressValue = this.calculateLargeElementProgress(rect, viewportHeight)
    }

    return oldProgress !== this.progressValue
  }

  async updateProgress() {
    await patch(window.location.href, {
      body: JSON.stringify({
        document: {
          progress: this.progressValue,
        }
      })
    })
  }

  isSmallElement(elementHeight, viewportHeight) {
    return elementHeight <= viewportHeight
  }

  calculateLargeElementProgress(rect, viewportHeight) {
    const scrolledPast = Math.max(0, -rect.top)
    const maxScroll = rect.height - viewportHeight
    return Math.min(1, Math.max(0, (scrolledPast / maxScroll)))
  }

  scrollToProgress() {
    const viewportHeight = window.innerHeight
    const elementHeight = this.element.offsetHeight
    const elementTop = this.element.offsetTop

    if (this.isSmallElement(elementHeight, viewportHeight)) {
      window.scrollTo({ top: elementTop })
    } else {
      const scrollRange = elementHeight - viewportHeight
      let targetScroll = elementTop + (this.progressValue * scrollRange)
      window.scrollTo({ top: targetScroll })
    }
  }

  connectListeners() {
    document.addEventListener("scroll", debounce(() => {
      const now = Date.now()
      const elapsed = now - this.lastUpdatedValue
      const finished = this.syncProgress() && this.progressValue === 1

      if (finished || elapsed >= UPDATE_RATE_LIMIT) {
        this.lastUpdatedValue = now
        this.updateProgress()
        clearTimeout(this.rateLimitTimeout)
      } else {
        clearTimeout(this.rateLimitTimeout)
        this.rateLimitTimeout = setTimeout(() => {
          this.lastUpdatedValue = Date.now()
          this.updateProgress()
        }, UPDATE_RATE_LIMIT - elapsed)
      }
    }, DEBOUNCE), { signal: this.abortController.signal })
  }
}

function debounce(func, delay) {
  let timeout
  return () => {
    clearTimeout(timeout)
    timeout = setTimeout(func, delay)
  }
}
