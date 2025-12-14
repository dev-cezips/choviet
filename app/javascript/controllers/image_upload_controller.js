import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "preview", "dropZone"]

  connect() {
    this.setupDragAndDrop()
  }

  handleFiles(event) {
    const files = event.target.files || event.dataTransfer?.files
    if (!files) return

    if (files.length > 10) {
      alert('Chỉ được tải tối đa 10 ảnh')
      this.fileInputTarget.value = ''
      return
    }

    this.displayPreview(files)
  }

  displayPreview(files) {
    this.previewTarget.innerHTML = ''
    this.previewTarget.classList.remove('hidden')

    // Add header with image count
    const header = document.createElement('div')
    header.className = 'col-span-full mb-2'
    header.innerHTML = `
      <p class="text-sm text-gray-600">
        <span class="font-medium">${files.length}</span> ảnh đã chọn
        ${files.length >= 5 ? '<span class="text-green-600 ml-2">✓ Đủ ảnh cho bài mua bán</span>' : ''}
      </p>
    `
    this.previewTarget.appendChild(header)

    Array.from(files).forEach((file, index) => {
      if (!file.type.startsWith('image/')) return

      const reader = new FileReader()
      reader.onload = (e) => {
        const div = document.createElement('div')
        div.className = 'relative group'
        div.innerHTML = `
          <img src="${e.target.result}" class="w-full h-24 object-cover rounded-lg border-2 border-gray-200">
          <button type="button" data-action="click->image-upload#removeImage" data-index="${index}" 
                  class="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity shadow-sm hover:bg-red-600">
            ✕
          </button>
          ${index === 0 ? '<span class="absolute bottom-1 left-1 bg-blue-500 text-white text-xs px-2 py-1 rounded">Ảnh đại diện</span>' : ''}
        `
        this.previewTarget.appendChild(div)
      }
      reader.readAsDataURL(file)
    })
  }

  removeImage(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.index)
    
    const dt = new DataTransfer()
    const files = Array.from(this.fileInputTarget.files)
    files.splice(index, 1)
    files.forEach(file => dt.items.add(file))
    this.fileInputTarget.files = dt.files
    
    if (files.length === 0) {
      this.previewTarget.classList.add('hidden')
      this.previewTarget.innerHTML = ''
    } else {
      this.displayPreview(this.fileInputTarget.files)
    }
  }

  setupDragAndDrop() {
    this.dropZoneTarget.addEventListener('dragover', this.handleDragOver.bind(this))
    this.dropZoneTarget.addEventListener('dragleave', this.handleDragLeave.bind(this))
    this.dropZoneTarget.addEventListener('drop', this.handleDrop.bind(this))
  }

  handleDragOver(e) {
    e.preventDefault()
    this.dropZoneTarget.classList.add('border-blue-500', 'bg-blue-50')
  }

  handleDragLeave(e) {
    e.preventDefault()
    this.dropZoneTarget.classList.remove('border-blue-500', 'bg-blue-50')
  }

  handleDrop(e) {
    e.preventDefault()
    this.dropZoneTarget.classList.remove('border-blue-500', 'bg-blue-50')
    
    const files = e.dataTransfer.files
    this.fileInputTarget.files = files
    this.handleFiles({ dataTransfer: { files } })
  }
}