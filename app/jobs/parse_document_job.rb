class ParseDocumentJob < ApplicationJob
  def perform(document_id)
    document = Document.find_by(id: document_id)
    raw_html = document.content

    if raw_html.nil?
      return unless document&.url.present?

      response = HttpUtilities.get(document.url)
      return unless response

      raw_html = response.body
    end

    doc = Nokogiri::HTML(raw_html)
    doc.css("script, style").remove
    cleaned_html = doc.to_html

    parsed_data = ReadingParser.parse(cleaned_html)
    document.update(parsed_data: parsed_data)
  end
end
