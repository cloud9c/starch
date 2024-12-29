class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @subscriptions = current_user&.subscriptions
  end
end
