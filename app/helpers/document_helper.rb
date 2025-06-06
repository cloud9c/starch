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
end
