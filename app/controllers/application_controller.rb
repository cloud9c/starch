class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :redirect_www_to_non_www

  def redirect_www_to_non_www
    if request.host.start_with?('www.')
      non_www_host = request.host.sub('www.', '')
      redirect_url = "#{request.protocol}#{non_www_host}#{request.fullpath}"
      redirect_to redirect_url, status: :moved_permanently, allow_other_host: true
    end
  end
end
