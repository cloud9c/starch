module Resource::Epub
  extend ActiveSupport::Concern

  def initialize_epub
    chapters = extract_epub_chapters
    update!(metadata: { epub: { chapters: chapters } })
  end

  require "zip"
  private
    def extract_epub_chapters
      chapters = []
      file.open do |tempfile|
        Zip::File.open(tempfile.path) do |zip_file|
          zip_file.each do |entry|
            if entry.name.end_with?(".xhtml") && !entry.name.include?("nav")
              chapters << {
                title: File.basename(entry.name, ".xhtml"),
                file: entry.name,
                order: chapters.length + 1
              }
            end
          end
        end
      end
      chapters
    end
end
