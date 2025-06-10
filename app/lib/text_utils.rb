module TextUtils
  extend self

  def format_html(html)
    return nil if html.nil? || html.empty?

    text = Nokogiri::HTML(html).xpath("//text()").map(&:text).join(" ")
    text.gsub(/\s+/, " ").strip
  end

  require "image_size/uri"
  def extract_thumbnail(html, min_width: 100, min_height: 100)
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
end
