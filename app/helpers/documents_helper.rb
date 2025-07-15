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
    when Upload
      upload = document.upload
      title = upload.mime_type.to_s.upcase
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

  def render_document(document)
    wrap_content(document) do
      case
      when document.youtube?
        render_youtube(document)
      when document.email?
        render_email(document)
      when document.display_type == :html
        render_html(document)
      end
    end
  end

  private
    def wrap_content(document)
      content_tag :article, class: document_classes(document),
        data: {
          controller: "update-#{document.display_type}-progress",
          "update_#{document.display_type}_progress_progress_value": document.progress,
          "update_#{document.display_type}_progress_progress_identifier_value": document.progress_identifier
        } do
        yield if block_given?
      end
    end

    def document_classes(document)
      classes = [ "document__container" ]

      case document.display_type
      when :html
        if document.email?
          classes << "document__container--email"
        else
          classes << "typography"
        end
      end

      classes.join(" ")
    end

    def render_email(document)
      email_content = sanitize document.content,
        tags: BASE_TAGS + %w[style head meta html body], attributes: BASE_ATTRIBUTES + %w[style]

        custom_styles = <<~CSS
          <style>
            body{margin:16px;padding:0;}
            * {
              max-width: var(--page-width);
              height: auto;
            }
          </style>
        CSS
        email_content = custom_styles + email_content

      content_tag :iframe, nil, srcdoc: email_content,
        onload: "this.style.height = this.contentWindow.document.documentElement.scrollHeight + 'px'"
    end

    def render_html(document)
      sanitize document.content, tags: BASE_TAGS, attributes: BASE_ATTRIBUTES
    end

    def render_youtube(document)
      content_tag :div, nil, id: "video-container", data: {
        youtube_id: document.youtube_id
      }
    end
end
