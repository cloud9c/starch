module Document::Displayable
  extend ActiveSupport::Concern

  YOUTUBE_REGEX = /^(?:https?:\/\/|\/\/)?(?:www\.|m\.|.+\.)?
    (?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|shorts\/|feeds\/api\/videos\/|watch\?v=|watch\?.+&v=))
    ([\w-]{11})(?![\w-])/x

  def mime_type
    return resource.mime_type.to_sym if resource?
    :html
  end

  def display_type
    return :youtube if youtube?

    mime_type
  end

  def youtube?
    youtube_id.present?
  end

  def youtube_id
    match = YOUTUBE_REGEX.match(url)
    return nil unless match

    match[1]
  end
end
