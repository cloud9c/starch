module FormatUtils
  extend self

  def format_html(html, base_url = nil)
    doc = Nokogiri::HTML.fragment(html)

    doc.css("script").remove

    rename_ids(doc)
    format_links(doc, base_url)

    doc.to_html
  end

  def format_text(html)
    return nil if html.nil? || html.empty?

    doc = Nokogiri::HTML(html)

    body = doc.at('body') || doc
    text = body.xpath(".//text()").map(&:text).join(" ")
    text.gsub(/\s+/, " ").strip
  end

  def extract_description(content)
    text = FormatUtils.format_text(content)
    return nil if text.empty?

    text.strip.gsub(/\s+/, " ")[0...300]
  end

  require "image_size/uri"
  def find_thumbnail(html, min_width: 250, min_height: 250)
    doc = Nokogiri::HTML(html)

    images = doc.css("img")

    images.each do |image|
      src = image["src"]

      begin
        size = ImageSize.url(src).size
      rescue
        next
      end

      next if size.nil?
      width, height = size
      return src if width >= min_width && height >= min_height
    end

    find_thumbnail(html, min_width: 100, min_height: 100) unless min_width == 100 && min_height == 100
  end

  def find_icon(url)
    origin_url = UrlUtils.get_origin(url)
    root_url = UrlUtils.get_root(url)

    icon_url = try_find_icon(origin_url)

    if icon_url.nil? && root_url != origin_url
      icon_url = try_find_icon(root_url)
    end

    icon_url
  end

  private
    def try_find_icon(url)
      selectors = [
        'link[rel~="apple-touch-icon"]',
        'link[rel="shortcut icon"]',
        'link[rel~="icon"]'
      ]

      http = HTTPX.plugin(:follow_redirects, max_redirects: 10).plugin(:ssrf_filter)
      response = http.get(url)
      return nil if response.error

      # Use the final URL after redirects
      final_url = response.uri.to_s

      body = response.body.to_s
      doc = Nokogiri::HTML(body)

      icon_href = selectors.map { |sel| doc.css(sel).first&.[](:href) }.compact.first

      if icon_href
        URI.join(final_url, icon_href).to_s
      else
        # Fallback to favicon.ico using the final URL
        favicon_url = URI.join(final_url, "/favicon.ico").to_s
        favicon_response = http.head(favicon_url)
        favicon_response.error ? nil : favicon_url
      end
    end

    def format_links(doc, base_url)
      url_related_attributes = %w[href src]
      url_related_attributes.each do |attr|
        doc.css("[#{attr}]").each do |element|
          begin
            # Skip anchor links (relative fragments)
            next if element[attr]&.start_with?("#")

            element[attr] = URI.join(base_url, element[attr]).to_s if base_url.present?
            element["target"] = "_blank"
          rescue URI::InvalidURIError
            element.remove_attribute(attr)
          end
        end
      end
    end

    def rename_ids(doc)
      id_mappings = {}
      prefix = "_html_#{SecureRandom.hex(4)}_"

      # Rename IDs
      doc.css("[id]:not([id=''])").each do |element|
        old_id = element["id"]
        new_id = "#{prefix}#{old_id}"
        id_mappings[old_id] = new_id
        element["id"] = new_id
      end

      # Update anchor links to match renamed IDs
      doc.css("a[href^='#']").each do |link|
        href = link["href"]
        old_id = href[1..-1] # Remove the '#'
        if id_mappings[old_id]
          link["href"] = "##{id_mappings[old_id]}"
        end
      end
    end
end
