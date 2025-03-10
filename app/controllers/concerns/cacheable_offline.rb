module CacheableOffline
  extend ActiveSupport::Concern

  included do
    # Set cache headers for offline access
    after_action :set_offline_cache_headers, only: [ :show ]
  end

  private

  def set_offline_cache_headers
    response.headers["Cache-Control"] = "private, max-age=86400" # 24 hours
  end
end
