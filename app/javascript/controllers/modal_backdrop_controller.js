import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // Prevent background scroll when modal opens
    document.body.style.overflow = "hidden"
  }

  disconnect() {
    // Re-enable background scroll when modal closes
    document.body.style.overflow = ""
  }

  closeOnBackdrop(event) {
    // Only close if clicking the backdrop itself, not the modal content
    if (event.target === this.element) {
      this.close()
    }
  }

  close() {
    // Clear both modal frames (new standard + legacy compat)
    const modalFrame = document.getElementById("modal")
    const reportModalFrame = document.getElementById("report_modal")

    if (modalFrame) modalFrame.innerHTML = ""
    if (reportModalFrame) reportModalFrame.innerHTML = ""
  }
}
