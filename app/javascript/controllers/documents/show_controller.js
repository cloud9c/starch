import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class DocumentsShowController extends Controller {
  connect() {
    new FetchRequest('POST',  window.location.href.split('?')[0] + "/read").perform()
  }
}