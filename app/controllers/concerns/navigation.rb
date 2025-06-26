module Navigation
  extend ActiveSupport::Concern

  included do
    helper_method :clear_all_or_redirect_to
  end

  private

  def clear_all_or_redirect_to(url, options = {})
    if hotwire_native_app?
      redirect_to clear_all_path
    else
      redirect_to url, options
    end
  end
end
