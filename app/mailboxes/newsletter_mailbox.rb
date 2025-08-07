class NewsletterMailbox < ApplicationMailbox
  def process
    email_address = find_email_address(mail.to.first)
    return unless email_address

    display_name = mail[:from].display_names.first

    email_sender = EmailSender.find_or_create_by(email_address: mail.from.first)
    email_sender.display_name = display_name
    email_sender.save if email_sender.changed?

    document = email_sender.documents.create!(
      title: mail.subject,
      content: extract_content,
      published_at: mail.date,
      user: email_address.user,
      status: :inbox
    )

    inbound_email.incinerate
  end

  private
    def extract_content
      html_part = mail.parts.find { |part| part.content_type.include?("text/html") }
      body = html_part.present? ? html_part.body.decoded : mail.body.decoded
      encoded_body = body.force_encoding("UTF-8")

      html_part.present? ? format_html(encoded_body) : encoded_body
    end

    def format_html(html)
      premailer = Premailer.new(html, with_html_string: true)
      inline_html = premailer.to_inline_css rescue html

      doc = Nokogiri::HTML(inline_html)
      doc.css("script").remove
      doc.to_html
    end

    def find_email_address(recipient_email)
      return nil unless recipient_email.include?("@#{EmailAddress::DOMAIN}")

      username = recipient_email.split("@").first.downcase
      EmailAddress.find_by(username: username)
    end
end
