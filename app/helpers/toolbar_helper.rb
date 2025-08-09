module ToolbarHelper
  extend self

  def toolbar_toggle(text, icon, status, checkedStatus = status)
    checked = @document.status == status

    tag.button type: :submit,
    name: "document[status]",
    value: checked ? checkedStatus : status,
    class: "toggle icon--#{icon} shortcut-hotkey shortcut-hotkey__corner toolbar__action",
    "aria-label": text,
    data: {
      controller: "shortcut",
      "shortcut-hotkey-value": status[0].downcase,
      checked: checked
    } do
      text
    end
  end

  def toolbar_move
    tag.details class: "shortcut-hotkey shortcut-hotkey__corner relative", data: {
        controller: "shortcut",
        "shortcut-hotkey-value": "m"
      } do
      concat tag.summary "Move", "aria-label": "Move",
        class: "toggle icon--move toolbar__action"
      concat toolbar_move_options
    end
  end

  def toolbar_move_options
    tag.div class: "action-group action-group--popup action-group--grid" do
      concat tag.h1 "Move this document to...", class: "action-group__title push_half--bottom"
      concat toolbar_move_option("inbox")
      concat toolbar_move_option("feed")
    end
  end

  def toolbar_move_option(status)
    checked = @document.status == status

    tag.button type: :submit,
    name: "document[status]",
    value: status,
    class: "toggle icon--#{status} toolbar__action action-group__item shortcut-hotkey shortcut-hotkey__corner",
    "aria-label": "Move to #{status.capitalize}",
    data: {
      controller: "shortcut",
      "shortcut-hotkey-value": status[0].downcase,
      checked: checked
    } do
      status.capitalize
    end
  end
end
