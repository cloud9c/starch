class NewsletterMailbox < ApplicationMailbox
  def process
    email_address = find_email_address(mail.to.first)
    return unless email_address

    display_name = mail.from.display_names.first

    email_sender = EmailSender.find_or_create_by(email_address: mail.from.first) do |sender|
      sender.display_name = display_name
    end
    
    if email_sender.display_name != display_name
      email_sender.update(display_name: display_name)
    end

    document = email_sender.documents.create!(
      title: mail.subject,
      content: extract_content,
      published_at: mail.date,
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
      inline_html = premailer.to_inline_css rescue html

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
