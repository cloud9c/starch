import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'
import { loadStripe } from '@stripe/stripe-js' 

export default class extends Controller {
  static targets = ["container"]
  static values = {
    stripeKey: String
  }

  async connect() {
    this.stripe = await loadStripe(this.stripeKeyValue)
    
    try {
      const checkout = await this.stripe.initEmbeddedCheckout({
        fetchClientSecret: this.fetchClientSecret,
      })

      checkout.mount(this.containerTarget)
    } catch (error) {
      console.error("Error initializing checkout", error)
    }
  }
  
  async fetchClientSecret() {
    const request = new FetchRequest('POST', '/user/billing/create_checkout_session')
    const response = await request.perform()
    
    if (response.ok) {
      const data = await response.json
      return data.clientSecret
    } else {
      throw new Error(`Request failed with status: ${response.status}`)
    }
  }
}
