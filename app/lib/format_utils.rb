module FormatUtils
  extend self

  def format_html(html, base_url = nil)
    doc = Nokogiri::HTML.fragment(html)

    doc.css("style, script").remove
    format_styling(doc)
    format_links(doc, base_url)

    doc.to_html
  end

  def format_text(html)
    return nil if html.nil? || html.empty?

    text = Nokogiri::HTML(html).xpath("//text()").map(&:text).join(" ")
    text.gsub(/\s+/, " ").strip
  end

  require "image_size/uri"
  def find_thumbnail(html, min_width: 100, min_height: 100)
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

    nil
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

    def format_styling(doc)
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
