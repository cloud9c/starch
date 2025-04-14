module ApplicationHelper
  def render_document_html(html, url)
    sanitized_html = sanitize(html,
      tags: %w[
        h1 h2 h3 h4 h5 h6 h7 h8 br b i strong em a pre code img tt div ins del sup sub
        p ol ul table thead tbody tfoot blockquote dl dt dd kbd q samp var hr ruby rt
        rp li tr td th s strike summary details figure figcaption audio video source
        small iframe
      ],
      attributes: %w[
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
        vspace itemprop id
      ])

    doc = Nokogiri::HTML(sanitized_html)

    # convert all urls to absolute
    base = UrlUtils.normalize(url)

    url_related_attributes = %w[href src longdesc cite poster action usemap]
    url_related_attributes.each do |attr|
      doc.css("[#{attr}]").each do |element|
        begin
          element[attr] = URI.join(base, element[attr]).to_s if element[attr].present?
        rescue URI::InvalidURIError
          element.remove_attribute(attr)
        end
      end
    end

    # sandbox iframes
    doc.css("iframe").each do |iframe|
      iframe[attr] = "allow-scripts allow-same-origin" unless iframe["sandbox"]
    end

    doc.to_html.html_safe
  end

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
