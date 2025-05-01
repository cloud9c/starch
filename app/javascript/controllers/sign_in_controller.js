import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  connect() {
    Turbo.visit("/session/new")
  }
}
