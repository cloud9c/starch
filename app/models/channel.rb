class Channel < ApplicationRecord
  validates :domain, presence: true, uniqueness: true
  validate :valid_domain_format
  before_validation :normalize_domain

  private

  def normalize_domain
    return if domain.blank?
    
    # Remove protocol and www if present, convert to lowercase
    self.domain = domain.to_s.downcase
      .gsub(%r{^https?://}, '')
      .gsub(/^www\./, '')
  end

  def valid_domain_format
    domain_regex = /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$/
    
    unless domain.match?(domain_regex)
      errors.add(:domain, "must be a valid domain format (e.g., example.com)")
    end
  end
end