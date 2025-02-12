class ParseDocumentJob < ApplicationJob
  def perform(document_id)
    document = Document.find_by(id: document_id)
    raw_content = document.content

    if raw_content.nil?
      return unless document&.url.present?
      
      response = HttpUtilities.get(document.url)
      return unless response

      raw_content = response.body
    end
    
    parsed_content = ReadingParser.parse(raw_content)
    document.update(parsed_content: parsed_content)
  end
end