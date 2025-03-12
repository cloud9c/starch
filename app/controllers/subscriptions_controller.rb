class SubscriptionsController < ApplicationController
  before_action :load_subscriptions, only: [ :index, :create ]

  def create
    feed_url = HttpHelper.get_feed_url(params[:feed_url])
    return head :unprocessable_entity unless feed_url
    
    ActiveRecord::Base.transaction do
      channel = Channel.find_or_create_by!(feed_url: feed_url)

      @subscription = Current.user.subscriptions.create!(channel: channel)
      @subscription.add_recent_entries if channel.initial_poll_complete?
    end
  end

  def update
    @subscription = Current.user.subscriptions.find(params[:id])

    if @subscription.update(subscription_params) && subscription_params[:view_extracted].present?
      # cache busting
      channel_id = @subscription.channel_id
      document_ids = DocumentState.joins(document: { entry: :channel })
                                    .where(user_id: Current.user.id)
                                    .where(entries: { channel_id: channel_id })
                                    .pluck(:document_id)

      timestamp = Time.now.to_i
      document_ids.each do |doc_id|
        session["document_#{doc_id}_updated_at"] = timestamp
      end
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
