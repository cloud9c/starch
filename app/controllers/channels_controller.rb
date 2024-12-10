class ChannelsController < ApplicationRecord
  def create
    @channel = Channel.new(channel_params)
    if @channel.save
      render json: @channel, status: :created
    else
      render json: @channel.errors, status: :unprocessable_entity
    end
  end

  private
end