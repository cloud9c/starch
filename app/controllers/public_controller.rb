class PublicController < ApplicationController
  layout "public"
  allow_unauthenticated_access

  def index
    return unless authenticated?

    if params[:format] == "html"
      redirect_to "#{inbox_path}?format=html"
    else
      redirect_to inbox_path
    end
  end

  def clear_all
    unless hotwire_native_app?
      redirect_to root_path
    end
  end
end
