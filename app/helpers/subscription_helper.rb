module SubscriptionHelper
  extend self

  def button_to_copy_email_address(email_address)
    tag.button email_address,
      class: "btn btn--icon btn--subtle btn--rounded btn--surface icon--copy newsletter-email-address",
      data: {
        controller: "copy-to-clipboard", action: "copy-to-clipboard#copy",
        copy_to_clipboard_success_class: "btn--success", copy_to_clipboard_content_value: email_address
      }
  end
end
