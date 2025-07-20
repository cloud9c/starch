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

  def source_container(document)
    case document.source
    when Entry
      feed = document.feed
      title = feed.title || feed.feed_url
      icon = feed.icon
      fallback_icon = "icons/rss.svg"
    when EmailSender
      sender = document.sender
      title = sender.display_name || sender.email_address
      icon = sender.icon
      fallback_icon = "icons/email.svg"
    when Resource
      resource = document.resource
      title = resource.mime_type.to_s.upcase
      # icon = "icons/#{title.downcase}.svg"
      fallback_icon = "icons/file.svg"
    end

    content_tag :div, class: "source-container" do
      picture = capture do
        content_tag :picture do
          source_tag = icon.present? ? content_tag(:source, "", srcset: icon) : ""
          image_tag_html = image_tag(fallback_icon, width: 24)
          (source_tag + image_tag_html).html_safe
        end
      end

      concat picture
      concat content_tag(:span, title)
    end
  end

  def render_header(document)
    content_tag :header, class: "document__header" do
      source_container(document) +
      content_tag(:hgroup) do
        content_tag :h1, class: "document__title" do
          link_to document.title, document.url, target: "_blank"
        end
      end +
      content_tag(:div, class: "document__metadata-row") do
        content_tag(:span, document.author) +
        if document.published_at
          content_tag(:span, local_time(document.published_at, "%b %d, %Y"))
        else
          "".html_safe
        end
      end
    end
  end

  def render_document(document)
    wrap_content(document) do
      case document.render_type
      when :youtube
        render_youtube(document)
      when :email
        render_email(document)
      when :html
        render_html(document)
      end
    end
  end

  private
    def wrap_content(document)
      content_tag :article, class: container_classes(document.render_type),
        data: container_data(document) do
        yield if block_given?
      end
    end

    def container_data(document)
      case document.render_type
      when :html, :email
        {
          controller: "html",
          html_progress_value: document.progress
        }
      when :youtube
        {
          controller: "youtube",
          youtube_start_value: document.progress_identifier
        }
      when :ebook
        {
          controller: "ebook",
          ebook_url_value: rails_blob_url(document.resource.file),
          ebook_cfi_value: document.progress_identifier
        }
      end
    end

    def container_classes(render_type)
      classes = [ "document__container" ]

      case render_type
      when :html
        classes << "typography document__container--html"
      when :email
        classes << "document__container--email"
      when :ebook
        classes << "document__container--ebook"
      end

      classes.join(" ")
    end

    def render_html(document)
      sanitize document.content, tags: BASE_TAGS, attributes: BASE_ATTRIBUTES
    end

    def render_youtube(document)
      content_tag :div, nil, id: "video-container", data: {
        youtube_id: document.youtube_id
      }
    end

    def render_email(document)
      style = <<~CSS
        <style>
          * {
            max-width: 100% !important;
            height: auto !important;
          }
          *:where(:not(html, iframe, canvas, img, svg, video, audio):not(svg *, symbol *)) {
              all: unset;
              display: revert;
          }
        </style>
      CSS
      html = style + document.content

      content_tag :iframe, nil, srcdoc: html, class: "document__container--iframe",
        sandbox: "allow-same-origin allow-scripts",
        onload: "this.style.height = this.contentWindow.document.documentElement.scrollHeight + 'px'"
    end
end
