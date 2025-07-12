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

  # Upload
  def upload?
    source.is_a?(Upload)
  end

  def upload
    source if upload?
  end
end
