class NewsletterMailbox < ApplicationMailbox
  def process
    sender = mail.from.first
    recipient = mail.to.first
    subject = mail.subject
    content = extract_content
    author = mail[:from].display_names.first
    email_address = find_email_address(recipient)

    unless email_address
      Rails.logger.warn "No EmailAddress found for #{recipient}, skipping email processing"
      return
    end

    document = email_address.documents.create!(
      title: subject,
      content: content,
      author: author,
      published_at: mail.date,
      identifier: mail.from.first
    )

    document.document_states.create!(
      user: email_address.user,
      status: :inbox
    )
  end

  private
    def extract_content
      content = mail.body.decoded
      html_part = mail.parts.find { |part| part.content_type.include?("text/html") }

      if html_part.present?
        html = html_part.body&.decoded
        content = format_html(html)
      end

      content
    end

    def format_html(html)
      premailer = Premailer.new(html, with_html_string: true)

      inline_html = premailer.to_inline_css

      doc = Nokogiri::HTML(inline_html)
      body = doc.at_css("body")

      if body
        body.name = "div"
        body.to_html
      else
        doc.to_html
      end
    end

    def find_email_address(recipient_email)
      return nil unless recipient_email.include?("@#{EmailAddress::DOMAIN}")

      username = recipient_email.split("@").first.downcase
      EmailAddress.find_by(username: username)
    end
end
