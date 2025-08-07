require "zip"

class ActiveStorage::Previewer::EpubPreviewer < ActiveStorage::Previewer
  def self.accept?(blob)
    blob.content_type == "application/epub+zip"
  end

  def preview(**options)
    download_blob_to_tempfile do |input|
      cover_data = extract_cover(input)
      if cover_data
        # Detect the actual image format
        extension = detect_extension(cover_data)
        content_type = extension == ".png" ? "image/png" : "image/jpeg"

        Tempfile.create([ "cover", extension ]) do |output|
          output.binmode
          output.write(cover_data)
          output.rewind
          yield io: output, filename: "#{blob.filename.base}#{extension}", content_type: content_type
        end
      end
    end
  end

  private

  def extract_cover(file)
    Zip::File.open(file.path) do |zip|
      # Try the OPF method first
      cover_data = extract_from_opf(zip)
      return cover_data if cover_data

      # Fallback: look for common cover file names
      cover_data = extract_from_common_names(zip)
      return cover_data if cover_data

      nil
    end
  rescue
    nil
  end

  def extract_from_opf(zip)
    opf_path = find_opf_path(zip)
    return unless opf_path

    opf = Nokogiri::XML(zip.read(opf_path))
    cover_href = find_cover_href(opf)
    return unless cover_href

    cover_path = File.join(File.dirname(opf_path), cover_href)
    zip.read(cover_path)
  rescue
    nil
  end

  def extract_from_common_names(zip)
    # Common cover file patterns
    patterns = [
      /cover\.(jpe?g|png|gif)$/i,
      /front\.(jpe?g|png|gif)$/i
    ]

    # Look through all zip entries for cover images
    zip.entries.each do |entry|
      filename = File.basename(entry.name)
      if patterns.any? { |pattern| filename.match?(pattern) }
        return zip.read(entry.name)
      end
    end

    nil
  end

  def find_opf_path(zip)
    container = Nokogiri::XML(zip.read("META-INF/container.xml"))
    container.at("rootfile")["full-path"]
  rescue
    nil
  end

  def find_cover_href(opf)
    # EPUB 3: Use CSS selectors to avoid namespace issues
    cover = opf.css("item[properties='cover-image']").first
    return cover["href"] if cover

    # EPUB 3: properties containing "cover-image" (for cases with multiple properties)
    cover = opf.css("item[properties*='cover-image']").first
    return cover["href"] if cover

    # EPUB 2: meta name="cover"
    meta = opf.css("meta[name='cover']").first
    if meta
      cover_id = meta["content"]
      cover = opf.css("item[id='#{cover_id}']").first
      return cover["href"] if cover
    end

    # Additional fallback: look for items with "cover" in href
    cover = opf.css("item[href*='cover']").first
    return cover["href"] if cover

    nil
  end

  def detect_extension(data)
    case data[0..3]
    when "\x89PNG"
      ".png"
    when "\xFF\xD8\xFF"
      ".jpg"
    when "GIF8"
      ".gif"
    else
      ".jpg"
    end
  end
end
