module Document::FromUpload
  extend ActiveSupport::Concern

  def upload?
    source.is_a?(Upload)
  end

  def upload
    source if upload?
  end
end
