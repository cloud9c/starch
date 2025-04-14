class SubscriptionsController < ApplicationController
  def index
    @subscriptions = Current.user.subscriptions
  end

  def create
    permitted = params.expect(subscription: [ :feed_url, :to_inbox ])

    feed_url = ChannelUtils.find_feed_url(permitted[:feed_url])
    return head :unprocessable_entity unless feed_url

    channel = Channel.find_or_create_by!(feed_url: feed_url)
    return head :unprocessable_entity unless channel.persisted?

    Rails.logger.debug permitted.inspect

    to_inbox = ActiveModel::Type::Boolean.new.cast(permitted[:to_inbox])

    @subscription = Current.user.subscriptions.create!(channel: channel, to_inbox: to_inbox)
    @subscription.add_recent_entries if channel.initial_poll_complete?
  end

  def update
    permitted = params.expect(subscription: [ :view_extracted, :to_inbox ])

    @subscription = Current.user.subscriptions.find(params[:id])
    @subscription.update(permitted)

    head :ok
  end

  def destroy
    @subscription = Current.user.subscriptions.find(params[:id])
    head :unprocessable_entity unless @subscription.destroy!
  end
end
