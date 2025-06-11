module DocumentHelper
  extend self

  def render_video(document)
    youtube_regex = /^(?:https?:\/\/|\/\/)?(?:www\.|m\.|.+\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|shorts\/|feeds\/api\/videos\/|watch\?v=|watch\?.+&v=))([\w-]{11})(?![\w-])/

    match = youtube_regex.match(document.url)
    return unless match

    youtube_id = match[1]

    content_tag :div, class: "video-container" do
      content_tag :iframe, nil,
                  src: "https://www.youtube.com/embed/#{youtube_id}",
                  width: "100%",
                  height: "100%",
                  frameborder: 0,
                  allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture",
                  allowfullscreen: true,
                  title: document.title
    end
  end

  def source_container(document)
    source = document.source

    if source.is_a?(Entry)
      feed = source.feed
      title = feed.title || feed.feed_url
      icon = feed.icon
      fallback_icon = "icons/rss.svg"
    elsif source.is_a?(EmailAddress)
      title = document.author
      fallback_icon = "icons/email.svg"
    end
    
content_tag :div, class: "source-container" do
  picture = capture do
    content_tag :picture do
      source_tag = icon.present? ? content_tag(:source, "", srcset: icon) : ""
      image_tag_html = image_tag(fallback_icon, width: 24, alt: "#{title} icon")
      (source_tag + image_tag_html).html_safe
    end
  end
  
  concat picture
  concat content_tag(:span, title)
end
  end
end
