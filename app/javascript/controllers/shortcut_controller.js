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
    const isInInputField = 
        event.target.tagName === 'INPUT' || 
        event.target.tagName === 'TEXTAREA' || 
        event.target.isContentEditable;
    
    if (isInInputField) return;

    const hotkeys = this.hotkeyValue.split(/[\s,]+/);

    if (hotkeys.includes(event.key)) {
      event.preventDefault();
      this.performDefaultAction();
    }
  }

  performDefaultAction() {
    const tagName = this.element.tagName.toLowerCase();
    
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
        this.element.focus();
        break;
    }
  }
}
