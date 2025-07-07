import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateAvatar()
  }

  updateAvatar() {
    const activeAvatar = this.element.querySelector(".subscription-avatar[data-active=true]")
    if (activeAvatar)
      activeAvatar.parentElement.scrollTo({left: activeAvatar.offsetLeft});
  }

  toggle(event) {
    const avatarLink = event.currentTarget
    const isActive = avatarLink.dataset.active === "true"
    const subscriptionId = avatarLink.dataset.subscriptionId

    const url = new URL(window.location)

    if (isActive) {
      url.searchParams.delete('subscription')
    } else {
      url.searchParams.set('subscription', subscriptionId)
    }

    window.history.pushState({}, '', url)
  }
}
