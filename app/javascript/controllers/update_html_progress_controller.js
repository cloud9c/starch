import { Controller } from "@hotwired/stimulus"
import { patch } from '@rails/request.js'

const SYNC_RATE_LIMIT = 3000
const SCROLL_DEBOUNCE = 500

export default class extends Controller {
  static values = {
    progress: Number,
    lastSynced: Number,
  }

  connect() {
    this.abortController = new AbortController();
    if (this.progressValue > 0) {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this.scrollToProgress()
        })
      })
    }

    this.connectListeners()
  }

  disconnect() {
    clearTimeout(this.rateLimitTimeout)
    this.abortController.abort();
  }

  async updateProgress() {
    const body = {
      document: {
        progress: this.progressValue,
      }
    }

    await patch(window.location.href, {
      body: JSON.stringify(body)
    })
  }

  syncProgress() {
    const rect = this.element.getBoundingClientRect()
    const viewportHeight = window.innerHeight

    if (this.isSmallElement(rect.height, viewportHeight)) {
      this.progressValue = rect.top <= 0 && rect.bottom >= 0 ? 100 : 0
    } else {
      this.progressValue = this.calculateLargeElementProgress(rect, viewportHeight)
    }
  }

  isSmallElement(elementHeight, viewportHeight) {
    return elementHeight <= viewportHeight
  }

  calculateLargeElementProgress(rect, viewportHeight) {
    const scrolledPast = Math.max(0, -rect.top)
    const maxScroll = rect.height - viewportHeight
    return Math.min(100, Math.max(0, (scrolledPast / maxScroll) * 100))
  }

  scrollToProgress() {
    const viewportHeight = window.innerHeight
    const elementHeight = this.element.offsetHeight
    const elementTop = this.element.offsetTop
    
    if (this.isSmallElement(elementHeight, viewportHeight)) {
      window.scrollTo({ top: elementTop })
    } else {
      const maxScroll = elementHeight - viewportHeight
      const targetScroll = (this.progressValue / 100) * maxScroll
      window.scrollTo({ top: elementTop + targetScroll })
    }
  }

  connectListeners() {
    document.addEventListener("scroll", debounce(() => {
      const now = Date.now()
      const elapsed = now - this.lastSyncedValue

      this.syncProgress()

      if (elapsed >= SYNC_RATE_LIMIT) {
        this.lastSyncedValue = now
        this.updateProgress()
        clearTimeout(this.rateLimitTimeout)
      } else {
        clearTimeout(this.rateLimitTimeout)
        this.rateLimitTimeout = setTimeout(() => {
          this.lastSyncedValue = Date.now()
          this.updateProgress()
        }, SYNC_RATE_LIMIT - elapsed)
      }
    }, SCROLL_DEBOUNCE), { signal: this.abortController.signal })
  }
}

function  debounce(func, delay) {
  let timeout
  return () => {
    clearTimeout(timeout)
    timeout = setTimeout(func, delay)
  }
}