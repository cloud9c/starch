class ChannelsController < ApplicationController
  def create
    domain = params[:channel][:domain].to_s.gsub(%r{^https?://}, "")
    domain = domain.gsub(/\/.*$/, "")
    domain = PublicSuffix.domain(domain)

    @channel = Channel.new(domain: domain)

    if @channel.save
      SpiderChannelJob.perform_later(@channel)
      @channels = Channel.all
      respond_to do |format|
        format.turbo_stream
        format.json { head :no_content }
      end
    else
      render json: @channel.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @channel = Channel.find(params[:id])
    if @channel.destroy
      @channels = Channel.all
      respond_to do |format|
        format.turbo_stream
        format.json { head :no_content }
      end
    else
      render json: @channel.errors, status: :unprocessable_entity
    end
  end
end
