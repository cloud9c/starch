class BillingsController < ApplicationController
  allow_unprovisioned_access

  MONTHLY_PRICE_ID = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :paid_subscription_monthly_price_id)

  def show
    if Current.user.paid?
      redirect_to_billing_portal and return
    end

    render :checkout
  end

  def required_checkout
    render :checkout
  end

  def return
    checkout_session = Stripe::Checkout::Session.retrieve(params[:session_id]) rescue nil

    if checkout_session&.status == "complete"
      handle_checkout_completed(params[:session_id])

      if params[:hotwire_native_app] == "true"
        render :return and return
      end

      flash[:notice] = "Subscription activated!"

      redirect_to inbox_path and return
    end

    flash[:alert] = "Your payment was not completed. Please try again."
    redirect_to :user_billing
  end

  def create_checkout_session
    parameters = {
      ui_mode: "embedded",
      line_items: [ {
        price: MONTHLY_PRICE_ID,
        quantity: 1
      } ],
      mode: "subscription",
      return_url: "#{request.base_url}/user/billing/return?session_id={CHECKOUT_SESSION_ID}&hotwire_native_app=#{hotwire_native_app?}",
      automatic_tax: { enabled: true },
      allow_promotion_codes: true,
      payment_method_collection: "if_required",
      redirect_on_completion: "if_required"
    }

    if Current.user.stripe_customer_id.present?
      parameters[:customer] = Current.user.stripe_customer_id
    else
      parameters[:customer_email] = Current.user.email_address
    end

    session = Stripe::Checkout::Session.create(parameters)

    render json: { clientSecret: session.client_secret }
  end

  def has_paid
    handle_checkout_completed(params[:session_id])

    render json: { paid: Current.user.paid? }, status: :ok
  end

  private

  def redirect_to_billing_portal
    customer = Stripe::Customer.retrieve(Current.user.stripe_customer_id)

    session = Stripe::BillingPortal::Session.create({
      customer: customer.id
    })

    redirect_to session.url, allow_other_host: true
  end

  def handle_checkout_completed(session_id)
    checkout_session = Stripe::Checkout::Session.retrieve(session_id) rescue nil

    if checkout_session&.status == "complete"
      customer = Stripe::Customer.retrieve(checkout_session.customer)
      subscription = Stripe::Subscription.retrieve(checkout_session.subscription)
      StripeUtils.handle_customer_created(customer)
      StripeUtils.handle_subscription_created(subscription)
    end
  end
end
