import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    hotkey: String
  }

  connect() {
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    const nodeName = event.target.nodeName.toLowerCase();
    if (event.target.nodeType === 1 && (nodeName === "textarea" ||
        (nodeName === "input" && /^(?:text|email|number|search|tel|url|password)$/i.test(event.target.type)))) {
      return
    }

    const hotkeys = this.hotkeyValue.split(" ").flatMap(key => [key, key.toUpperCase()]);

    if (hotkeys.includes(event.key)) {
      event.preventDefault();
      this.performDefaultAction();
    }
  }

  performDefaultAction() {
    const tagName = this.element.tagName.toLowerCase();
    const inputType = this.element.getAttribute('type');

    switch(tagName) {
      case 'a':
        this.element.click();
        break; 
      case 'details':
        this.element.open = !this.element.open;
        break;
      case 'button':
        this.element.click();
        break;
      case 'input':
        if (inputType === 'radio') {
          this.element.checked = true;
          this.element.dispatchEvent(new Event('change', { bubbles: true }));
        } else {
          this.element.focus();
        }
        break;
    }
  }
}
