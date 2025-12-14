import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]
  
  connect() {
    this.loadFromLocalStorage()
    this.setupAutoSave()
    this.hasChanges = false
  }
  
  disconnect() {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
    }
  }
  
  setupAutoSave() {
    // Auto-save every 30 seconds if there are changes
    setInterval(() => {
      if (this.hasChanges) {
        this.saveToLocalStorage()
        this.hasChanges = false
      }
    }, 30000)
  }
  
  inputChanged() {
    this.hasChanges = true
    
    // Clear existing timer
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
    }
    
    // Save after 2 seconds of no activity
    this.saveTimer = setTimeout(() => {
      this.saveToLocalStorage()
      this.hasChanges = false
    }, 2000)
  }
  
  saveToLocalStorage() {
    const formData = {}
    
    // Collect all input values
    this.inputTargets.forEach(input => {
      if (input.type === 'radio') {
        if (input.checked) {
          formData[input.name] = input.value
        }
      } else if (input.type === 'checkbox') {
        formData[input.name] = input.checked
      } else {
        formData[input.name] = input.value
      }
    })
    
    // Save to localStorage
    const key = this.getStorageKey()
    localStorage.setItem(key, JSON.stringify(formData))
    
    // Show status
    this.showStatus("Đã lưu tự động")
  }
  
  loadFromLocalStorage() {
    const key = this.getStorageKey()
    const savedData = localStorage.getItem(key)
    
    if (savedData) {
      const formData = JSON.parse(savedData)
      const hasData = Object.values(formData).some(val => val && val !== '')
      
      if (hasData && confirm('Bạn có muốn khôi phục bài viết đang soạn không?')) {
        // Restore form data
        this.inputTargets.forEach(input => {
          const savedValue = formData[input.name]
          
          if (savedValue !== undefined) {
            if (input.type === 'radio') {
              input.checked = input.value === savedValue
              if (input.checked && input.dataset.action) {
                // Trigger any associated actions
                input.dispatchEvent(new Event('change'))
              }
            } else if (input.type === 'checkbox') {
              input.checked = savedValue
            } else {
              input.value = savedValue
            }
          }
        })
        
        this.showStatus("Đã khôi phục bài viết")
      } else {
        // Clear saved data
        localStorage.removeItem(key)
      }
    }
  }
  
  clearSaved() {
    const key = this.getStorageKey()
    localStorage.removeItem(key)
  }
  
  getStorageKey() {
    // Use post ID for edit, or 'new' for new posts
    const postId = this.data.get("postId") || "new"
    return `post_draft_${postId}`
  }
  
  showStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.classList.remove('hidden')
      
      setTimeout(() => {
        this.statusTarget.classList.add('hidden')
      }, 3000)
    }
  }
  
  // Called when form is successfully submitted
  formSubmitted() {
    this.clearSaved()
  }
}