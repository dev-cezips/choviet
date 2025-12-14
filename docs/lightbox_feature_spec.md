# Feature: 이미지 클릭 시 원본 팝업(라이트박스) 기능 추가

---

## 1. 기능 개요

현재 게시글 상세 페이지의 이미지 슬라이더는 `object-cover` 방식으로 표시되고 있어 상하좌우가 잘리는 문제가 있음. 중고거래 특성상 **상품의 실제 상태(기스, 모서리, 찍힘)**를 상세하게 보여주는 기능이 필수이므로, 아래 요구사항을 충족하는 Lightbox(이미지 확대) 기능을 추가한다.

---

## 2. 요구사항 (Requirements)

### 🎯 필수 요구사항
1. 슬라이더 이미지 클릭 시 화면 전체 팝업으로 원본 이미지가 표시되어야 한다.
2. 팝업 배경은 검은색 반투명(`black/90`) 으로 적용.
3. 팝업된 이미지는 `object-contain` 으로 비율을 유지하며 최대 크기로 표시.
4. 팝업은 다음 영역을 클릭하면 닫혀야 한다:
   - 배경 영역
   - 우측 상단의 닫기 버튼(X)
5. 팝업이 열린 동안에는 배경 스크롤이 비활성화된다.
6. 모바일에서는 핀치 줌(pinch zoom) 이 가능해야 한다.
7. 이미지는 모델이 가진 실제 원본 이미지 URL로 불러온다.

---

## 3. 기술 스택
- Rails 8
- Hotwire + Turbo
- Stimulus.js
- TailwindCSS

---

## 4. Stimulus Controller 구현

**파일 경로:** `app/javascript/controllers/lightbox_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "fullImage"]

  open(event) {
    event.preventDefault()
    const src = event.currentTarget.dataset.src

    this.fullImageTarget.src = src
    this.modalTarget.classList.remove("hidden")

    document.body.style.overflow = "hidden"
  }

  close(event) {
    const clickedBackground = event.target === this.modalTarget
    const clickedCloseButton = event.target.closest('[data-action="click->lightbox#close"]')

    if (clickedBackground || clickedCloseButton) {
      this.modalTarget.classList.add("hidden")
      this.fullImageTarget.src = ""
      document.body.style.overflow = "auto"
    }
  }
}
```

---

## 5. View 수정

### 5.1 슬라이더 이미지 태그에 이벤트 추가

```erb
<%= image_tag image,
    class: "absolute block w-full h-full object-cover cursor-zoom-in",
    data: {
      action: "click->lightbox#open",
      src: url_for(image)
    }
%>
```

---

### 5.2 Lightbox 모달 추가

슬라이더 아래쪽에 아래 코드 삽입:

```erb
<div data-lightbox-target="modal"
     data-action="click->lightbox#close"
     class="hidden fixed inset-0 z-[100] bg-black/90 flex items-center justify-center p-4">

  <button class="absolute top-5 right-5 text-white p-2 hover:bg-white/20 rounded-full"
          data-action="click->lightbox#close">
    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M6 18L18 6M6 6l12 12" />
    </svg>
  </button>

  <img data-lightbox-target="fullImage"
       class="max-w-full max-h-full object-contain rounded-lg shadow-2xl"
       src=""
       alt="Full size image" />
</div>
```

---

## 6. Tailwind 스타일 가이드
- 팝업 배경: `bg-black/90`
- 닫기 버튼 활성화: `hover:bg-white/20`
- 이미지 표시: `object-contain`
- 최대 크기: `max-w-full max-h-full`
- z-index: `z-[100]`
- 팝업 transition(optional): fade-in 효과 가능 (선택)

---

## 7. 모바일 대응
- 모든 기능은 모바일에서도 정상 작동해야 한다.
- 핀치 줌을 지원하기 위해 `touch-action: none` 또는 기본 브라우저 제스처 유지.
- 이미지는 viewport 기준 90% 크기 안에서 표시됨.

---

## 8. 비고

### 추후 확장 가능 기능:
1. 좌우 넘김 기능 추가 (Lightbox 내에서 슬라이드 가능)
2. 더블탭 줌
3. EXIF 회전 자동 보정
4. 저화질 → 고화질 Progressive Loading

---

## 9. 개발 체크리스트

| 항목 | 완료 여부 |
|------|-----------|
| 이미지 클릭 시 라이트박스 열림 | ☐ |
| 팝업 이미지 원본 링크로 출력 | ☐ |
| 배경 클릭 → 라이트박스 닫힘 | ☐ |
| 닫기 버튼 → 라이트박스 닫힘 | ☐ |
| 라이트박스 상태에서 스크롤 막힘 | ☐ |
| 모바일 핀치 줌 확인 | ☐ |
| 다중 이미지 테스트 완료 | ☐ |

---

## 10. 스크린샷 예시 (필요 시 추가)

개발 완료 후 실제 라이트박스 동작 화면을 첨부 예정.

---