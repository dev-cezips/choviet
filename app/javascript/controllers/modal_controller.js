import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close(event) {
    event.preventDefault()
    
    // If inside a turbo frame, clear the frame
    const frame = this.element.closest('turbo-frame')
    if (frame) {
      frame.innerHTML = ''
    } else {
      // Otherwise, remove the modal element
      this.element.remove()
    }
  }
}