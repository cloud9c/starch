class SubscriptionsController < ApplicationController
  before_action :load_subscriptions, only: [ :index, :create ]

  def create
    channel = Channel.find_by(feed_url: params[:feed_url])

    unless channel
      feed_url = FeedUtilities.get_feed_url(params[:feed_url])

      return render status: :unprocessable_entity unless feed_url

      channel = Channel.find_or_initialize_by(feed_url: feed_url)

      return render status: :unprocessable_entity unless channel.save
    end

    @subscription = Subscription.create(channel: channel)

    return render status: :unprocessable_entity unless @subscription.persisted?

    channel.push_documents_to_new_users(Current.user.id)
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    render status: :unprocessable_entity unless @subscription.destroy!
  end

  private

  def load_subscriptions
    @subscriptions = Subscription.all
  end
end
