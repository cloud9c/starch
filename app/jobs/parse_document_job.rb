class ParseDocumentJob < ApplicationJob
  def perform(document_id)
    document = Document.find_by(id: document_id)
    content = document.content

    if content.nil?
      return unless document&.url.present?

      response = HttpHelper.get(document.url)
      return unless response

      raw_html = response.body
      doc = Nokogiri::HTML(raw_html)
      doc.css("script, style").remove
      content = doc.to_html
    end

    return unless content

    parsed_data = ReadingParser.parse(content)

    return unless parsed_data

    # only update key if value is non-nil
    document.update({
      title: parsed_data["title"],
      content: parsed_data["content"],
      description: parsed_data["excerpt"],
      author: parsed_data["byline"],
      published_at: parsed_data["publishedTime"]
    }.compact)
  end
end
