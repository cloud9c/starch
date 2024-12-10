class Channel < ApplicationRecord
  validates :domain, presence: true, uniqueness: true
  validate :valid_domain_format
  
  private
  
  def valid_domain_format
    uri = URI.parse(domain)
    errors.add(:domain, "invalid format") unless uri.host
  rescue URI::InvalidURIError
    errors.add(:domain, "invalid format")
  end
end