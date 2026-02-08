import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "indicator", "counter"]
  static values = { 
    index: { type: Number, default: 0 },
    autoplay: { type: Boolean, default: true },
    interval: { type: Number, default: 3000 }
  }

  connect() {
    console.log("[ImageSlider] Connected, slides:", this.slideTargets.length)
    this.slideTargets.forEach((slide, i) => {
      console.log(`[ImageSlider] Slide ${i}:`, slide.querySelector('img')?.src)
    })
    this.showSlide(this.indexValue)
    if (this.autoplayValue && this.slideTargets.length > 1) {
      this.startAutoplay()
    }
  }

  disconnect() {
    this.stopAutoplay()
  }

  // 다음 슬라이드 (무한 루프)
  next() {
    if (this.indexValue >= this.slideTargets.length - 1) {
      this.indexValue = 0  // 처음으로
    } else {
      this.indexValue++
    }
    this.showSlide(this.indexValue)
    this.restartAutoplay() // 자동재생 재시작
  }

  // 이전 슬라이드 (무한 루프)
  prev() {
    if (this.indexValue <= 0) {
      this.indexValue = this.slideTargets.length - 1  // 마지막으로
    } else {
      this.indexValue--
    }
    this.showSlide(this.indexValue)
    this.restartAutoplay() // 자동재생 재시작
  }

  // 특정 슬라이드로 이동
  goTo(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.indexValue = index
    this.showSlide(this.indexValue)
    this.restartAutoplay() // 자동재생 재시작
  }

  // 슬라이드 표시 업데이트
  showSlide(index) {
    console.log(`[ImageSlider] showSlide(${index}), total: ${this.slideTargets.length}`)
    // 모든 슬라이드 숨기기/보이기 (hidden 클래스 방식)
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove("hidden")
        console.log(`[ImageSlider] Showing slide ${i}`)
      } else {
        slide.classList.add("hidden")
      }
    })

    // 인디케이터 업데이트
    this.indicatorTargets.forEach((indicator, i) => {
      if (i === index) {
        indicator.classList.remove("bg-white/50", "scale-100")
        indicator.classList.add("bg-white", "scale-125")
      } else {
        indicator.classList.remove("bg-white", "scale-125")
        indicator.classList.add("bg-white/50", "scale-100")
      }
    })

    // 카운터 업데이트 (있는 경우)
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${index + 1} / ${this.slideTargets.length}`
    }
  }

  // 터치 스와이프 지원 (선택사항)
  touchStart(event) {
    this.touchStartX = event.touches[0].clientX
  }

  touchEnd(event) {
    if (!this.touchStartX) return
    
    const touchEndX = event.changedTouches[0].clientX
    const diff = this.touchStartX - touchEndX

    if (Math.abs(diff) > 50) { // 50px 이상 스와이프
      if (diff > 0) {
        this.next() // 왼쪽으로 스와이프 → 다음
      } else {
        this.prev() // 오른쪽으로 스와이프 → 이전
      }
    }

    this.touchStartX = null
  }

  // 자동 재생 시작
  startAutoplay() {
    this.stopAutoplay() // 기존 타이머 정리
    this.autoplayTimer = setInterval(() => {
      this.next()
    }, this.intervalValue)
  }

  // 자동 재생 정지
  stopAutoplay() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer)
      this.autoplayTimer = null
    }
  }

  // 사용자 상호작용 시 자동재생 재시작
  restartAutoplay() {
    if (this.autoplayValue && this.slideTargets.length > 1) {
      this.stopAutoplay()
      this.startAutoplay()
    }
  }

  // 자동재생 토글
  toggleAutoplay() {
    this.autoplayValue = !this.autoplayValue
    if (this.autoplayValue) {
      this.startAutoplay()
    } else {
      this.stopAutoplay()
    }
  }
}