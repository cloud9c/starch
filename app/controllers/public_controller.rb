class PublicController < ApplicationController
  layout "public"
  allow_unauthenticated_access

  def index
    redirect_to "#{inbox_path}?format=html" if authenticated?
  end
end
