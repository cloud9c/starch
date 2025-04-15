class SubscriptionsController < ApplicationController
  def index
    @subscriptions = Current.user.subscriptions
  end

  def create
    permitted = params.expect(subscription: [ :feed_url, :to_inbox ])

    feed_url = ChannelUtils.find_feed_url(permitted[:feed_url])

    unless feed_url
      @flash = { alert: "Couldn't find an RSS/Atom feed" }
      return render status: :bad_request
    end

    channel = Channel.find_or_create_by!(feed_url: feed_url)

    to_inbox = ActiveModel::Type::Boolean.new.cast(permitted[:to_inbox])

    subscription = Current.user.subscriptions.find_or_initialize_by(channel: channel, to_inbox: to_inbox)

    unless subscription.new_record?
      @flash = { alert: "Subscription already exists" }
      return render status: :conflict
    end

    subscription.save
    subscription.add_recent_entries if channel.initial_poll_complete?

    @subscription = subscription
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
