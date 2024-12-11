class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @channels = Channel.all
  end
end
