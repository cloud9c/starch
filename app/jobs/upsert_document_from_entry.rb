class UpsertDocumentFromEntry < ApplicationJob
  def perform(entry_id, syndicate)
    entry = Entry.find_by(id: entry_id)

    document_attributes = {
      title: entry.title,
      description: entry.description,
      author: entry.author,
      published_at: entry.published_at,
      url: entry.url,
      content: entry.content
    }

    if entry.url
      parsed_data = ReadingParser.parse(entry.url)

      parsed_attributes = {
        title: EntryHelper.format_text(parsed_data["title"]),
        content: EntryHelper.format_html(parsed_data["content"]),
        description: EntryHelper.format_text(parsed_data["excerpt"]),
        author: EntryHelper.format_text(parsed_data["byline"]),
        published_at: parsed_data["publishedTime"]
      }.compact

      document_attributes.merge!(parsed_attributes)
    end

    document = entry.document || entry.build_document
    document.update!(document_attributes)

    if syndicate
      entry.channel.users.each do |user|
        DocumentUserState.create!(
          user: user,
          document: document
        )
      end
    end
  end
end
