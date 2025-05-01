class PublicController < ApplicationController
  layout "public"
  allow_unauthenticated_access

  def index
    redirect_to "#{inbox_path}?format=html" if authenticated?
  end

  def redirect
    @url = params[:url] || new_session_path
  end
end
