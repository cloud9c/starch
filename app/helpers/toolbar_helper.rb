module ToolbarHelper
  extend self

  def toolbar_toggle(text, icon, status, checkedStatus = nil)
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
end
