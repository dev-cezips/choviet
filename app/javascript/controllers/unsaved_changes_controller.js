import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  
  connect() {
    this.hasChanges = false
    this.submitted = false
    
    // Add event listener for page unload
    this.handleBeforeUnload = this.handleBeforeUnload.bind(this)
    window.addEventListener("beforeunload", this.handleBeforeUnload)
    
    // Listen for Turbo navigation
    this.handleTurboBeforeVisit = this.handleTurboBeforeVisit.bind(this)
    document.addEventListener("turbo:before-visit", this.handleTurboBeforeVisit)
  }
  
  disconnect() {
    window.removeEventListener("beforeunload", this.handleBeforeUnload)
    document.removeEventListener("turbo:before-visit", this.handleTurboBeforeVisit)
  }
  
  // Called when any input changes
  inputChanged() {
    this.hasChanges = true
  }
  
  // Called when form is submitted
  formSubmitted() {
    this.submitted = true
    this.hasChanges = false
  }
  
  // Handle browser navigation away
  handleBeforeUnload(event) {
    if (this.hasChanges && !this.submitted) {
      event.preventDefault()
      event.returnValue = "Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời khỏi trang?"
      return event.returnValue
    }
  }
  
  // Handle Turbo navigation
  handleTurboBeforeVisit(event) {
    if (this.hasChanges && !this.submitted) {
      if (!confirm("Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời khỏi trang?")) {
        event.preventDefault()
      }
    }
  }
}