import { Controller } from "@hotwired/stimulus"
import { patch } from '@rails/request.js'

const SYNC_RATE_LIMIT = 5000
const SCROLL_DEBOUNCE = 150

export default class extends Controller {
  static values = {
    displayType: String,
    progress: Number,
    progressIdentifier: String,
    lastSynced: Number,
    updateUrl: String
  }

  connect() {
    this.updateUrlValue = window.location.href
    if (this.displayTypeValue === "html") this.connectHTML()
  }

  async updateProgress() {
    const body = { 
      document: {
        progress: this.progressValue,
        progress_identifier: this.progressIdentifierValue
      }
    }

    await patch(this.updateUrlValue, {
      body: JSON.stringify(body)
    })
  }

  debounce(func, delay) {
    let timeout
    return () => {
      clearTimeout(timeout)
      timeout = setTimeout(func, delay)
    }
  }

  connectHTML() {
    if (this.progressValue > 0) {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this.scrollToProgress()
        })
      })
    }

    this.connectHTMLListeners()
  }

  syncHTMLProgress() {
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

  connectHTMLListeners() {
    document.addEventListener("scroll", this.debounce(() => {
      const now = Date.now()
      const elapsed = now - this.lastSyncedValue

      this.syncHTMLProgress()

      if (elapsed >= SYNC_RATE_LIMIT) {
        this.lastSyncedValue = now
        this.updateProgress()
      } else {
        if (this.rateLimitTimeout) clearTimeout(this.rateLimitTimeout)
        this.rateLimitTimeout = setTimeout(() => {
          this.lastSyncedValue = Date.now()
          this.updateProgress()
        }, SYNC_RATE_LIMIT - elapsed)
      }
    }, SCROLL_DEBOUNCE))

    document.addEventListener("beforeunload", async (event) => {
      await this.updateProgress()
    })
  }
}
