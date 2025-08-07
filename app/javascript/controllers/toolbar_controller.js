import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  next(event) {
    if (event.detail.success) {
      history.back()
    }
  }
}
