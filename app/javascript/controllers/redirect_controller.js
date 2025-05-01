import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {
  static values = {
    url: String
  }
  
  connect() {
    if (this.urlValue !== "") {
      Turbo.visit(this.urlValue);
    }
  }
}
