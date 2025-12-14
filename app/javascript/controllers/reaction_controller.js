import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "button", "count"]
  
  connect() {
    console.log("Reaction controller connected")
  }
  
  submit(event) {
    event.preventDefault()
    const form = event.currentTarget
    
    fetch(form.action, {
      method: form.method,
      body: new FormData(form),
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok')
      return response.text()
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error:', error)
    })
  }
}