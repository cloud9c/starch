class SubscriptionsController < ApplicationController
  def index
    @subscriptions = Current.user.subscriptions
  end

  def create
    permitted = params.expect(subscription: [ :url, :to_inbox ])

    feed_url = Feedbag.find(permitted[:url]).first

    unless feed_url
      @flash = { alert: "Couldn't find an RSS/Atom feed" }
      return render status: :bad_request
    end

    feed = Feed.find_or_create_by!(feed_url: feed_url)

    to_inbox = ActiveModel::Type::Boolean.new.cast(permitted[:to_inbox])
    subscription = Current.user.subscriptions.find_or_create_by(feed: feed, to_inbox: to_inbox)

    if subscription.previously_new_record?
      subscription.add_recent_entries if to_inbox && feed.initial_poll_complete?
      @subscription = subscription
    else
      @flash = { alert: "Subscription already exists" }
      render status: :conflict
    end
  end

  def update
    permitted = params.expect(subscription: [ :view_extracted, :to_inbox ])

    @subscription = Current.user.subscriptions.find(params[:id])
    @subscription.update(permitted)

    head :ok
  end

  def destroy
    subscription = Current.user.subscriptions.destroy(params[:id])
    render turbo_stream: turbo_stream.remove(subscription)
  end
end
