module FormatUtils
  extend self

  def format_html(html, base_url = nil)
    doc = Nokogiri::HTML.fragment(html)

    format_styling(doc)
    format_links(doc, base_url)

    doc.to_html
  end

  def format_text(html)
    return nil if html.nil? || html.empty?

    text = Nokogiri::HTML(html).xpath("//text()").map(&:text).join(" ")
    text.gsub(/\s+/, " ").strip
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
      class_mappings = {}
      prefix = "_html_#{SecureRandom.hex(4)}_"

      # Rename IDs
      doc.css("[id]").each do |element|
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

      # Rename classes
      doc.css("[class]").each do |element|
        old_classes = element["class"].split(/\s+/)
        new_classes = old_classes.map do |old_class|
          class_mappings[old_class] ||= "#{prefix}#{old_class}"
        end
        element["class"] = new_classes.join(" ")
      end

      # Update style tags
      doc.css("style").each do |style_tag|
        css_content = style_tag.content

        # Replace ID selectors
        id_mappings.each do |old_id, new_id|
          css_content.gsub!(/##{Regexp.escape(old_id)}\b/, "##{new_id}")
        end

        # Replace class selectors
        class_mappings.each do |old_class, new_class|
          css_content.gsub!(/\.#{Regexp.escape(old_class)}\b/, ".#{new_class}")
        end

        style_tag.content = css_content
      end
    end
end
