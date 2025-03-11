class SubscriptionsController < ApplicationController
  before_action :load_subscriptions, only: [ :index, :create ]

  def create
    channel = Channel.find_by(feed_url: params[:feed_url])

    unless channel
      feed_url = HttpHelper.get_feed_url(params[:feed_url])

      return head :unprocessable_entity unless feed_url

      channel = Channel.find_or_initialize_by(feed_url: feed_url)

      return head :unprocessable_entity unless channel.save
    end

    @subscription = Current.user.subscriptions.create(channel: channel)
    head :unprocessable_entity unless @subscription.persisted?
  end

  def update
    @subscription = Current.user.subscriptions.find(params[:id])
    
    if @subscription.update(subscription_params)
      # Add a timestamp to session to bust Turbo cache for documents
      session[:preference_updated_at] = Time.now.to_i if subscription_params[:view_extracted].present?
    end
  end

  def destroy
    @subscription = Current.user.subscriptions.find(params[:id])
    head :unprocessable_entity unless @subscription.destroy!
  end

  private

  def load_subscriptions
    @subscriptions = Current.user.subscriptions
  end

  def subscription_params
    params.require(:subscription).permit(:view_extracted)
  end
end
