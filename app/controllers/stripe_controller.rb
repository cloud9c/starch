class StripeController < ApplicationController
  allow_unauthenticated_access
  protect_from_forgery except: :webhook
  STRIPE_WEBHOOK_SIGNING_SECRET = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook_signing_secret)

  def webhook
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, STRIPE_WEBHOOK_SIGNING_SECRET
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Error parsing payload: #{e.message}"
      return render json: { error: "Invalid payload" }, status: 400
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Error verifying webhook signature: #{e.message}"
      return render json: { error: "Invalid signature" }, status: 400
    end

    case event.type
    when "customer.created"
      customer = event.data.object
      StripeUtils.handle_customer_created(customer)
    when "customer.deleted"
      customer = event.data.object
      StripeUtils.handle_customer_deleted(customer)
    when "customer.subscription.created"
      subscription = event.data.object
      StripeUtils.handle_subscription_created(subscription)
    when "customer.subscription.updated"
      subscription = event.data.object
      StripeUtils.handle_subscription_updated(subscription)
    when "customer.subscription.deleted"
      subscription = event.data.object
      StripeUtils.handle_subscription_deleted(subscription)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    render json: { status: "success" }, status: 200
  end
end
