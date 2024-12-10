class UpdateChannelFeedJob < ApplicationJob
  require 'nokogiri'
  require 'httpx'

  def perform
    Channel.find_each do |channel|

    end
  end
end