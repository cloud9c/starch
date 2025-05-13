class PublicController < ApplicationController
  layout "public"
  allow_unauthenticated_access

  def index
    redirect_to inbox_path if authenticated?
  end

  def clear_all
    unless hotwire_native_app?
      redirect_to root_path
    end
  end
end
