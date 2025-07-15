module LayoutsHelper
  extend self

  def trial_banner
    return unless on_trial? && current_page?(inbox_path)

    days_remaining = (Current.user.created_at + 30.days - Time.current).to_i / 1.day

    link_to user_billing_path, id: "trial-banner" do
      content_tag(:span, "You have", class: "desktop-only") +
      " #{days_remaining} days left on your free trial. " +
      content_tag(:span, "Let's pay for Starch »")
    end
  end

  def navbar_left_section
    back_link_config = if controller_name == "documents" && action_name == "show"
      { url: :back, text: "Back" }
    elsif !current_page?(inbox_path)
      { url: inbox_path, text: "Inbox" }
    end

    content_tag(:div, id: "navbar__left") do
      back_link_content = if back_link_config
        link_to back_link_config[:text],
          back_link_config[:url],
          class: "btn btn--primary btn--icon icon--arrow-left web-only",
          data: {
            controller: "shortcut",
            shortcut_hotkey_value: "b"
          }
      else
        ""
      end

      search_content = content_tag(:search,
                                  class: "searchbar searchbar--transparent #{'hide' if current_page?(controller: :documents, action: :search)}") do
        form_with(url: search_path, method: :get) do |form|
          content_tag(:div, class: "searchfield-container") do
            form.search_field :q,
              id: nil,
              autocomplete: "off",
              value: params[:q],
              placeholder: "Search",
              autofocus: false,
              data: {
                "controller": "searchbar shortcut",
                "shortcut-hotkey-value": "/"
              }
          end
        end
      end

      back_link_content.to_s.html_safe + search_content
    end
  end

  def navbar_menu
    links = [
      { path: inbox_path, icon: "inbox", text: "Inbox", hotkey: "1" },
      { path: feed_path, icon: "feed", text: "Feed", hotkey: "2" },
      { path: later_path, icon: "later", text: "Later", hotkey: "3" }
    ]
    content_tag(:ol,
              id: "navbar__menu",
              class: "desktop-only") do
      links.map do |link|
        is_current = current_page?(link[:path])
        content_tag(:li) do
          link_to link[:path],
                  data: {
                    controller: "shortcut",
                    "shortcut-hotkey-value": link[:hotkey]
                  },
                  class: "icon icon--#{link[:icon]} text--primary",
                  "aria-current": (is_current ? "page" : nil) do
            content_tag(:span, link[:text])
          end
        end
      end.join.html_safe
    end
  end

  def navbar_user_hue
    ascii_value = navbar_user_title.ord

    (ascii_value % 360).to_f
  end

  def navbar_user_title
    Current.user.email_address[0]
  end

  def navbar_user
    content_tag(:div, id: "navbar__user__container") do
      link_to user_path,
              data: {
                controller: "shortcut",
                "shortcut-hotkey-value": "4"
              },
              id: "navbar__user",
              style: "--user-hue: #{navbar_user_hue}",
              "aria-label": "Me" do
        navbar_user_title
      end
    end
  end
end
