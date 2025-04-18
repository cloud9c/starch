module SanitizeUtils
  extend self

  SANITIZER = Rails::HTML5::SafeListSanitizer.new

  def sanitize_html(html)
    sanitized_html = SANITIZER.sanitize(html,
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
    sanitized_html.html_safe unless sanitized_html.nil?
  end

  def clean_html(html, url)
    doc = Nokogiri::HTML.fragment(sanitize_html(html))

    # convert all urls to absolute + open in new tab
    base = UrlUtils.normalize(url) rescue nil
    url_related_attributes = %w[href src longdesc cite poster action usemap]
    url_related_attributes.each do |attr|
      doc.css("[#{attr}]").each do |element|
        begin
          element[attr] = URI.join(base, element[attr]).to_s if element[attr].present? && base.present?
          element["target"] = "_blank"
        rescue URI::InvalidURIError
          element.remove_attribute(attr)
        end
      end
    end

    # sandbox iframes
    doc.css("iframe").each do |iframe|
      iframe["sandbox"] = "allow-scripts allow-same-origin" unless iframe["sandbox"]
    end

    # remove ids and classes
    doc.css("[id], [class]").each do |element|
      element.remove_attribute("id")
      element.remove_attribute("class")
    end

    doc.to_html
  end
end
