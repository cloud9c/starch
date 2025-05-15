import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static targets = ["container"]
  static values = {
    stripeKey: String,
  }

  async connect() {
    this.initializeStripe()
  }

  async initializeStripe() {
    this.stripe = Stripe(this.stripeKeyValue)

    try {
      const checkout = await this.stripe.initEmbeddedCheckout({
        fetchClientSecret: this.fetchClientSecret,
        onComplete: () => this.checkPaidStatus(checkout)
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

  async checkPaidStatus(checkout) {
    const request = new FetchRequest('GET', `/user/billing/has_paid?session_id=${checkout.embeddedCheckout.checkoutSessionId}`)
    const response = await request.perform()
    
    if (response.ok) {
      const data = await response.json
      if (data.paid) {
        Turbo.visit("/clear_all")
      }
    } else {
      console.error(`Failed to check payment status: ${response.status}`)
    }
  }
}
