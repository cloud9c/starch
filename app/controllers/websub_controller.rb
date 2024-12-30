class WebSubController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  def verify
    channel = Channel.find_by(url: params['hub.topic'])
    return head :not_found unless channel

    if params['hub.mode'] == 'subscribe'
      channel.update(hub_verified_at: Time.current)
      render plain: params['hub.challenge']
    else
      head :bad_request
    end
  end

  def receive
    channel = Channel.find_by(url: params['topic'])
    return head :not_found unless channel

    channel.update(feed_content: request.raw_post)
    head :ok
  end
end