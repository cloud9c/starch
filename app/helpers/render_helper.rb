module RenderHelper
  extend self
  MD_RENDERER = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

  def render_video(document)
    youtube_regex = /^(?:https?:\/\/)?(?:(?:www\.)?youtube.com\/watch\?v=|youtu.be\/)(\w+)$/

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
end
