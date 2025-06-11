module Document::FromEntry
  extend ActiveSupport::Concern

  def entry?
    source.is_a?(Entry)
  end

  def entry
    source if entry?
  end

  def feed?
    entry?
  end

  def feed
    entry&.feed
  end

  def url
    identifier if entry?
  end

  def url=(value)
    self.identifier = value if entry?
  end
end
