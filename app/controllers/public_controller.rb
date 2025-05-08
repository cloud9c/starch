class PublicController < ApplicationController
  layout "public"
  allow_unauthenticated_access

  def index
    redirect_to inbox_path if authenticated?
  end

  def redirect
    @url = params[:url]
  end
end
