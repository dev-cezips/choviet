import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["defaultHeader", "expandedHeader", "overlay", "searchInput"]
  
  connect() {
    // ESC 키로 닫기
    this.handleEscape = this.handleEscape.bind(this)
    this.isExpanded = false
  }

  expand(event) {
    event.preventDefault()
    this.isExpanded = true
    
    // 헤더 상태 전환
    this.defaultHeaderTarget.classList.add("hidden")
    this.expandedHeaderTarget.classList.remove("hidden")
    
    // 오버레이 표시 (선택적 - 매우 투명함)
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden")
    }
    
    // 검색 입력창에 포커스
    setTimeout(() => {
      this.searchInputTarget.focus()
    }, 100)
    
    // ESC 키 리스너 추가
    document.addEventListener("keydown", this.handleEscape)
  }

  collapse(event) {
    if (event) event.preventDefault()
    this.isExpanded = false
    
    // 헤더 상태 전환
    this.defaultHeaderTarget.classList.remove("hidden")
    this.expandedHeaderTarget.classList.add("hidden")
    
    // 오버레이 숨기기
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
    
    // ESC 키 리스너 제거
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.isExpanded) {
      this.collapse()
    }
  }

  // 오버레이 클릭시 닫기
  overlayClick(event) {
    if (event.target === event.currentTarget) {
      this.collapse()
    }
  }

  disconnect() {
    // 컨트롤러 연결 해제시 정리
    document.removeEventListener("keydown", this.handleEscape)
  }
}