module FormatUtils
  extend self

  def format_html(html, base_url = nil)
    doc = Nokogiri::HTML.fragment(html)

    doc.css("style, script").remove
    rename_ids(doc)
    format_links(doc, base_url)

    doc.to_html
  end

  def format_text(html)
    return nil if html.nil? || html.empty?

    text = Nokogiri::HTML(html).xpath("//text()").map(&:text).join(" ")
    text.gsub(/\s+/, " ").strip
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

    find_thumbnail(html, 100, 100) unless min_width == 100 && min_height == 100
  end

  def extract_description(content)
    text = FormatUtils.format_text(content)

    if text.present?
      self.description = text.strip.gsub(/\s+/, " ")[0...300]
    end
  end

  def find_icon(base_url)
    http = HTTPX.plugin(:follow_redirects).plugin(:ssrf_filter)
    response = http.get(base_url)
    return nil if response.error

    body = response.body.to_s.force_encoding("UTF-8")

    doc = Nokogiri::HTML(body)
    icon_url = doc.css('link[rel~="apple-touch-icon"], link[rel~="icon"]').map { |link| link[:href] }.first
    icon_url ||= "/favicon.ico"

    URI.join(base_url, icon_url).to_s rescue nil
  end

  private
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
