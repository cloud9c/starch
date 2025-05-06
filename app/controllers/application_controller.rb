class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :redirect_www_to_non_www

  def redirect_www_to_non_www
    if request.host.start_with?("www.")
      redirect_to request.original_url.sub("www.", ""), status: :moved_permanently
    end
  end
end
