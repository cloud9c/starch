class SubscriptionsController < ApplicationController
  before_action :load_subscriptions, only: [ :index, :create ]

  def create
    channel = Channel.find_by(feed_url: params[:feed_url])

    unless channel
      feed_url = HttpUtilities.get_feed_url(params[:feed_url])

      return head :unprocessable_entity unless feed_url

      channel = Channel.find_or_initialize_by(feed_url: feed_url)

      return head :unprocessable_entity unless channel.save

      UpdateChannelJob.perform_now(channel.id, initial=false)
    end

    @subscription = Current.user.subscriptions.create(channel: channel)

    head :unprocessable_entity unless @subscription.persisted?
  end

  def destroy
    @subscription = Current.user.subscriptions.find(params[:id])
    head :unprocessable_entity unless @subscription.destroy!
  end

  private

  def load_subscriptions
    @subscriptions = Current.user.subscriptions
  end
end
