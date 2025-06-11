module Document::FromEmailAddress
  extend ActiveSupport::Concern

  def email_address?
    source.is_a?(EmailAddress)
  end

  def email_address
    source if email_address?
  end

  def from
    identifier if email_address?
  end

  def from=(value)
    self.identifier = value if email_address?
  end
end
