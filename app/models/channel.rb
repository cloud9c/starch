class Channel < ApplicationRecord
  include PageParsable

  validates :domain, presence: true, uniqueness: true
  validate :validate_domain
  validate :validate_origin
  has_many :pages, dependent: :destroy
  has_many :feeds, dependent: :destroy

  private

  def validate_domain
    return errors.add(:domain, "can't be blank") if domain.blank?

    begin
      parsed_domain = PublicSuffix.parse(domain)

      unless PublicSuffix.valid?(domain)
        errors.add(:domain, "invalid domain")
      end
    rescue PublicSuffix::Error => e
      errors.add(:domain, "domain parsing error: #{e.message}")
    end
  end

  def validate_origin(origin = get_origin(self.domain))
    response = HTTPX.get(origin)

    return errors.add(:domain, "fetching error") if response.is_a?(HTTPX::ErrorResponse)
    return validate_origin(response.headers["location"]) if response.status == 301
    return errors.add(:domain, "status not ok ") if response&.status != 200

    doc = Nokogiri::HTML(response.body.to_s)

    self.title = get_title(doc)
    self.description = get_description(doc)

    candidates = [
      doc.at_css('link[rel~="icon"]')&.[]("href"),
      "/favicon.ico"
    ].compact
    self.image = get_icon(candidates, origin)
  end
end
