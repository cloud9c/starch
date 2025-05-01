class PublicController < ApplicationController
  layout "public"
  allow_unauthenticated_access

  def index
    redirect_to "#{inbox_path}?format=html" if authenticated?
  end

  def sign_in
    if hotwire_native_app?
      redirect_to delayed_sign_in_path and return
    end

    redirect_to new_session_path
  end
end
