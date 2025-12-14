import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    event.preventDefault()
    event.stopPropagation()
    
    // 이미지 URL 가져오기 (여러 방식 지원)
    const imageUrl = event.currentTarget.dataset.lightboxUrlParam || 
                     event.currentTarget.dataset.src ||
                     event.currentTarget.src
    
    if (!imageUrl) {
      console.error("No image URL found")
      return
    }
    
    // 동적으로 모달 생성
    const modal = document.createElement("div")
    modal.className = "fixed inset-0 bg-black/90 flex items-center justify-center z-[9999] cursor-zoom-out"
    modal.innerHTML = `
      <img src="${imageUrl}" class="max-h-[90vh] max-w-[90vw] object-contain" />
      <button class="absolute top-4 right-4 text-white text-4xl">&times;</button>
    `
    
    modal.addEventListener("click", () => modal.remove())
    
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") modal.remove()
    }, { once: true })
    
    document.body.appendChild(modal)
  }
}