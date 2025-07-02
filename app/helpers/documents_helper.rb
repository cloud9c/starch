module DocumentsHelper
  extend self

  BASE_TAGS = %w[
        h1 h2 h3 h4 h5 h6 br b i strong em a pre code img tt div ins del sup sub
        p ol ul table thead tbody tfoot blockquote dl dt dd kbd q samp var hr ruby rt
        rp li tr td th s strike summary details figure figcaption audio video source
        small iframe]
  BASE_ATTRIBUTES = %w[
        href src longdesc itemscope itemtype cite
        poster playsinline loop muted controls preload
        align width height
        abbr accept accept-charset accesskey action alt axis
        border cellpadding cellspacing char charoff charset
        checked clear cols colspan color compact coords
        datetime dir disabled enctype for frame headers
        hreflang hspace ismap label lang maxlength
        media method multiple name nohref noshade nowrap
        open prompt readonly rel rev rows rowspan rules
        scope selected shape size span start summary
        tabindex target title type usemap valign value
        vspace itemprop id]

  def sanitize_document(document)
    case document.source
    when Entry
      sanitize document.content, tags: BASE_TAGS, attributes: BASE_ATTRIBUTES, remove_contents: %w[style script]
    when EmailAddress
      sanitize document.content, tags: BASE_TAGS, attributes: BASE_ATTRIBUTES + %w[style], remove_contents: %w[style script]
    else
      document.content
    end
  end

  def render_video(document)
    youtube_regex = /^(?:https?:\/\/|\/\/)?(?:www\.|m\.|.+\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|shorts\/|feeds\/api\/videos\/|watch\?v=|watch\?.+&v=))([\w-]{11})(?![\w-])/

    match = youtube_regex.match(document.identifier)
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
    case document.source
    when Entry
      feed = document.source.feed
      title = feed.title || feed.feed_url
      icon = feed.icon
      fallback_icon = "icons/rss.svg"
    when EmailAddress
      title = document.author || document.identifier
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
