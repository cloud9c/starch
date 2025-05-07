module StripeUtils
  extend self

  def handle_user_destroyed(user)
    return unless user.stripe_customer_id.present?

    begin
      Stripe::Customer.delete(user.stripe_customer_id)
      Rails.logger.info "Deleted Stripe customer: #{user.stripe_customer_id} for user #{user.id}"
    rescue Stripe::StripeError => e
      Rails.logger.error "Error deleting Stripe customer: #{e.message} for user #{user.id}, customer #{user.stripe_customer_id}"
    end
  end

  def handle_customer_created(customer)
    user = User.find_by!(email_address: customer.email)

    user.update(stripe_customer_id: customer.id)
    Rails.logger.info "Stored Stripe customer ID: #{customer.id} for user #{user.id}"
  end

  def handle_customer_deleted(customer)
    user = User.find_by!(stripe_customer_id: customer.id)

    user.update(stripe_customer_id: nil, paid: false)
    Rails.logger.info "Cleared Stripe customer ID and paid status for user #{user.id}"
  end

  def handle_subscription_created(subscription)
    user = User.find_by!(stripe_customer_id: subscription.customer)

    if subscription.status == "active"
      user.update(paid: true)
      Rails.logger.info "User #{user.id} marked as paid, subscription created: #{subscription.id}"
    end
  end

  def handle_subscription_updated(subscription)
    user = User.find_by!(stripe_customer_id: subscription.customer)

    case subscription.status
    when "active", "trialing"
      user.update(paid: true)
      Rails.logger.info "User #{user.id} marked as paid, subscription updated: #{subscription.id}"
    when "incomplete", "incomplete_expired", "past_due", "canceled", "unpaid", "paused"
      user.update(paid: false)
      Rails.logger.info "User #{user.id} marked as unpaid, subscription updated: #{subscription.id}"
    end
  end

  def handle_subscription_deleted(subscription)
    user = User.find_by!(stripe_customer_id: subscription.customer)

    user.update(paid: false)
    Rails.logger.info "User #{user.id} marked as unpaid, subscription deleted: #{subscription.id}"
  end
end
