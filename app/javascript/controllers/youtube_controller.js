import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js"

const UPDATE_RATE_LIMIT = 3000
const DEBOUNCE = 500

export default class extends Controller {
  static values = {
    start: Number,
    lastUpdated: Number
  }

  connect() {
    if (window.YT) {
      this.initializePlayer()
    } else {
      window.onYouTubeIframeAPIReady = () => {
        this.initializePlayer()
      }

      const tag = document.createElement("script")
      tag.src = "https://www.youtube.com/iframe_api"
      const firstScriptTag = document.getElementsByTagName("script")[0]
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
    }

    this.debouncedUpdateProgress = debounce(() => {
      const now = Date.now()
      const elapsed = now - this.lastUpdatedValue
      const ended = this.player.getPlayerState() === YT.PlayerState.ENDED

      if (ended || elapsed >= UPDATE_RATE_LIMIT) {
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
    }, DEBOUNCE)
  }

  initializePlayer() {
    this.player = new YT.Player("video-container", {
      videoId: document.getElementById("video-container").dataset.youtubeId,
      playerVars: {
        "playsinline": 0,
        "rel": 0,
        "start": Math.floor(this.startValue)
      },
      events: {
        "onReady": (event) => this.onPlayerReady(event),
        "onStateChange": (event) => this.onPlayerStateChange(event)
      }
    })
  }

  onPlayerReady(event) {
    // event.target.playVideo()
  }

  onPlayerStateChange(event) {
    if (event.data === YT.PlayerState.PLAYING || 
        event.data === YT.PlayerState.PAUSED ||
        event.data === YT.PlayerState.ENDED) {
      this.debouncedUpdateProgress()
    }
  }

  async updateProgress() {
    if (!this.player) return

    const progress = ended ? 1 : this.player.getCurrentTime() / this.player.getDuration()
    const progressIdentifier = ended ? 0 : Math.floor(this.player.getCurrentTime())

    await patch(window.location.href, {
      body: JSON.stringify({
        document: {
          progress: progress,
          progress_identifier: progressIdentifier
        }
      })
    })
  }

  disconnect() {
    this.player?.destroy()
  }
}

function debounce(func, delay) {
  let timeout
  return () => {
    clearTimeout(timeout)
    timeout = setTimeout(func, delay)
  }
}