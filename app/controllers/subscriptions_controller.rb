class SubscriptionsController < ApplicationController
  after_action :load_subscriptions, only: [:create, :destroy]
  
  def create
    feed_url = FeedParser.get_feed_url(params[:feed_url])

    channel = Channel.find_or_initialize_by(feed_url: feed_url)
    return head :unprocessable_entity unless channel.save

    @subscription = current_user.subscriptions.create(channel: channel)
    return head :unprocessable_entity unless @subscription.persisted?
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy!
  rescue ActiveRecord::RecordNotDestroyed => e
    flash[:error] = subscription.errors.full_messages.join(", ")
  end

  private

  def load_subscriptions
    @subscriptions = current_user.subscriptions
  end
end