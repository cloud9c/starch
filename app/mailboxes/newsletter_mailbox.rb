class NewsletterMailbox < ApplicationMailbox
  def process
    sender = mail.from.first
    subject = mail.subject
    content = extract_content

    puts "Received email with content: #{content}"
  end

  private

  def extract_content
    html_part = mail.parts.find { |part| part.content_type.include?("text/html") }
    text_part = mail.parts.find { |part| part.content_type.include?("text/plain") }

    html_part&.body&.decoded || text_part&.body&.decoded || mail.body.decoded
  end
end
