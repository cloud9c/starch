import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = {
    documentId: String
  }

  connect() {
    const url = new URL(window.location.href)
    const baseUrl = url.origin + url.pathname

    new FetchRequest('POST', `${baseUrl}/read`).perform()
  }
}
