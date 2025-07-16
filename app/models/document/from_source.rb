module Document::FromSource
  extend ActiveSupport::Concern

  # Entry
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

  # Email
  def email?
    source.is_a?(EmailSender)
  end

  def sender
    source if email?
  end

  # Resource
  def resource?
    source.is_a?(Resource)
  end

  def resource
    source if resource?
  end
end
