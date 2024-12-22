module UrlNormalizer
  extend ActiveSupport::Concern
  
  def normalize_url(url)
    url.chomp('/')
  end
end