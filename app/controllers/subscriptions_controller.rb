class SubscriptionsController < ApplicationController
  before_action :load_subscriptions, only: [:index]

  def create
    channel = Channel.find_by(feed_url: params[:feed_url])

    unless channel
      feed_url = UrlUtils.get_feed_url(params[:feed_url])
      channel = Channel.find_or_initialize_by(feed_url: feed_url)
      return head :unprocessable_entity unless channel.save
    end

    @subscription = current_user.subscriptions.create(channel: channel)
    head :unprocessable_entity unless @subscription.persisted?
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    return head :unprocessable_entity unless @subscription.destroy!
  end

  private

  def load_subscriptions
    @subscriptions = current_user.subscriptions
  end
end
