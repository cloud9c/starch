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
end
