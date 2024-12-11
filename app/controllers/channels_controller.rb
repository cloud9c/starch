class ChannelsController < ApplicationController
  require 'nokogiri'
  require 'httpx'
  require 'public_suffix'

  def create
    @channel = Channel.new(channel_params)
    @channel.domain = standardize_domain(@channel.domain)
    fetch_metadata(@channel)

    if @channel.save
      @channels = Channel.all
      respond_to do |format|
        format.turbo_stream
        format.json { render json: @channel, status: :created }
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

  private

  def channel_params
    params.require(:channel).permit(:domain)
  end

  def standardize_domain(domain)
    uri = URI.parse(domain.start_with?('http') ? domain : "https://#{domain}")
    parsed = PublicSuffix.parse(uri.host || domain)
    "#{parsed.domain}"
  rescue
    domain
  end

  def fetch_metadata(channel)
    begin
      HTTPX.get("https://#{channel.domain}")
      doc = Nokogiri::HTML(response.body.to_s)
      
      channel.title = doc.at_css('title')&.text&.strip
      channel.description = doc.at_css('meta[name="description"]')&.[]('content')&.strip
      channel.image = find_favicon(doc, channel.domain)
    rescue HTTPX::Error => e
      channel.errors.add(:domain, "Could not fetch metadata: #{e.message}")
    end
  end

  def find_favicon(doc, domain)
    candidates = [
      doc.at_css('link[rel="icon"]')&.[]('href'),
      doc.at_css('link[rel="shortcut icon"]')&.[]('href'),
      doc.at_css('link[rel="apple-touch-icon"]')&.[]('href'),
      "/favicon.ico",
      doc.at_css('meta[property="og:image"]')&.[]('content'),
      doc.at_css('meta[name="twitter:image"]')&.[]('content')
    ].compact

    image_url = candidates.find { |url| valid_image_url?(ensure_absolute_url(url, domain)) }
    ensure_absolute_url(image_url, domain)
  end

  def valid_image_url?(url)
    return false unless url
    response = HTTPX.head(url)
    response.headers["content-type"]&.start_with?('image/')
  rescue HTTPX::Error
    false
  end

  def ensure_absolute_url(url, domain)
    return nil unless url
    uri = URI.parse(url)
    return url if uri.absolute?
    "https://#{domain}#{url.start_with?('/') ? '' : '/'}#{url}"
  end
end