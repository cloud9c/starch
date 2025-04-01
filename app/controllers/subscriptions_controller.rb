class SubscriptionsController < ApplicationController
  def index
    @subscriptions = Current.user.subscriptions
  end

  def create
    feed_url = ChannelUtils.get_feed_url(params[:feed_url])
    return head :unprocessable_entity unless feed_url

    channel = Channel.find_or_create_by!(feed_url: feed_url)
    return head :unprocessable_entity unless channel.persisted?

    @subscription = Current.user.subscriptions.create!(channel: channel)
    @subscription.add_recent_entries if channel.initial_poll_complete?
  end

  def update
    @subscription = Current.user.subscriptions.find(params[:id])
    @subscription.update(params.require(:subscription).permit(:view_extracted))
  end

  def destroy
    @subscription = Current.user.subscriptions.find(params[:id])
    head :unprocessable_entity unless @subscription.destroy!
  end
end
