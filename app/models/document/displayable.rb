module Document::Displayable
  extend ActiveSupport::Concern

  def mime_type
    return upload.mime_type if upload?
    :html
  end

  def display_type
    return :youtube if youtube?

    case mime_type
    when :html
      if document.entry?
        :article
      else
        :email
      end
    else
      mime_type
    end
  end

  def youtube?
    youtube_id.present?
  end

  def youtube_id
    youtube_regex = /^(?:https?:\/\/|\/\/)?(?:www\.|m\.|.+\.)?
      (?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|shorts\/|feeds\/api\/videos\/|watch\?v=|watch\?.+&v=))
      ([\w-]{11})(?![\w-])/x

    match = youtube_regex.match(url)
    return nil unless match

    match[1]
  end
end
