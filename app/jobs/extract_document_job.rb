class ExtractDocumentJob < ApplicationJob
  def perform(document_id)
    document = Document.find!(document_id)
    document.extracted_data
  end
end
