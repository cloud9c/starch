class SubscriptionsController < ApplicationController
  before_action :load_subscriptions, only: [ :index, :create ]

  def create
    channel = Channel.find_by(feed_url: params[:feed_url])

    unless channel
      feed_url = HttpUtilities.get_feed_url(params[:feed_url])

      return head :unprocessable_entity unless feed_url

      channel = Channel.find_or_initialize_by(feed_url: feed_url)

      return head :unprocessable_entity unless channel.save
    end

    @subscription = Subscription.create(channel: channel)
    @documents = Document.with_channel_details

    head :unprocessable_entity unless @subscription.persisted?
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    head :unprocessable_entity unless @subscription.destroy!
  end

  private

  def load_subscriptions
    @subscriptions = Subscription.all
  end
end
