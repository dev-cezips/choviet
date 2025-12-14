import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { images: Array }
  
  open(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const images = JSON.parse(this.element.dataset.galleryImagesValue || "[]")
    
    // 전역 함수 정의
    window.openGalleryLightbox = function(url) {
      const lightbox = document.createElement("div")
      lightbox.className = "fixed inset-0 bg-black/95 z-[10000] flex items-center justify-center cursor-zoom-out"
      lightbox.innerHTML = `<img src="${url}" class="max-h-[90vh] max-w-[90vw] object-contain">`
      lightbox.onclick = () => lightbox.remove()
      document.addEventListener('keydown', function handleEsc(e) {
        if (e.key === 'Escape') {
          lightbox.remove()
          document.removeEventListener('keydown', handleEsc)
        }
      })
      document.body.appendChild(lightbox)
    }
    
    // 갤러리 닫기 헬퍼 함수
    const closeGallery = () => {
      modal.remove()
      // 사이트 헤더 복원
      document.querySelector('nav')?.style.setProperty('display', '')
    }
    
    // 갤러리 모달 생성
    const modal = document.createElement("div")
    modal.className = "fixed inset-0 bg-black/95 z-[9999] overflow-y-auto gallery-modal"
    modal.innerHTML = `
      <!-- 배경 클릭용 오버레이 -->
      <div class="absolute inset-0" data-gallery-overlay></div>
      
      <!-- 실제 콘텐츠 (배경 위에) -->
      <div class="relative z-10">
        <!-- 헤더 -->
        <div class="bg-black p-4 flex justify-between items-center">
          <button class="flex items-center gap-2 text-white hover:text-gray-300"
                  data-gallery-close>
            <span class="text-2xl">←</span>
            <span class="font-medium">Quay lại</span>
          </button>
          <h2 class="text-white text-lg font-bold">Tất cả ảnh (${images.length})</h2>
          <button class="text-white text-3xl p-2 hover:text-gray-300"
                  data-gallery-close>&times;</button>
        </div>
        
        <!-- 이미지 그리드 -->
        <div class="grid grid-cols-2 md:grid-cols-3 gap-2 p-4">
          ${images.map((url, i) => `
            <img src="${url}" 
                 class="w-full h-48 object-cover rounded-lg cursor-pointer hover:opacity-80 transition"
                 onclick="event.stopPropagation(); window.openGalleryLightbox('${url}')"
                 alt="Image ${i + 1}">
          `).join('')}
        </div>
      </div>
    `
    
    // 닫기 버튼들에 이벤트 추가
    modal.querySelectorAll('[data-gallery-close]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation()
        closeGallery()
      })
    })
    
    // 배경 오버레이 클릭으로 닫기
    const overlay = modal.querySelector('[data-gallery-overlay]')
    overlay.addEventListener('click', () => {
      closeGallery()
    })
    
    // ESC 키로 닫기
    const handleEsc = (e) => {
      if (e.key === 'Escape') {
        closeGallery()
        document.removeEventListener('keydown', handleEsc)
      }
    }
    document.addEventListener('keydown', handleEsc)
    
    document.body.appendChild(modal)
    
    // 사이트 헤더 숨기기
    document.querySelector('nav')?.style.setProperty('display', 'none')
  }
}