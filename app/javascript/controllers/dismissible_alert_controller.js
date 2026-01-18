import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "POST" }
  }

  dismiss() {
    this.element.style.display = "none"

    if (this.urlValue) {
      fetch(this.urlValue, {
        method: this.methodValue,
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content,
          "Content-Type": "application/json"
        }
      })
    }
  }
}
