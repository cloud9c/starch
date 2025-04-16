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
    const nodeName = this.element.nodeName.toLowerCase();
    if (this.element.nodeType === 1 && (nodeName === "textarea" ||
        (nodeName === "input" && /^(?:text|email|number|search|tel|url|password)$/i.test(this.element.type)))) {
      return
    }

    const hotkeys = [this.hotkeyValue, this.hotkeyValue.toUpperCase()]

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
        Turbo.visit(this.element.getAttribute('href'));
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
