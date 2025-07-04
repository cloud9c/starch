class NewsletterMailbox < ApplicationMailbox
  def process
    sender = mail.from.first
    recipient = mail.to.first
    subject = mail.subject
    content = extract_content
    display_name = mail[:from].display_names.first
    email_address = find_email_address(recipient)

    unless email_address
      Rails.logger.warn "No EmailAddress found for #{recipient}, skipping email processing"
      return
    end

    email_sender = EmailSender.find_or_initialize_by(email_address: sender)

    if email_sender.new_record?
      email_sender.display_name = display_name
      email_sender.icon = FormatUtils.find_icon(sender.split("@").last)
      email_sender.save!
    end

    document = email_sender.documents.create!(
      title: subject,
      content: content,
      published_at: mail.date,
      url: mail.from.first
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
      html = html.force_encoding("UTF-8") unless html.valid_encoding?

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
