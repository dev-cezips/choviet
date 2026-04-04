# Choviet 프로젝트 컨텍스트

## 프로젝트 개요
- **이름**: Chợ Việt (쵸비엣)
- **비전**: 타지에서도 성장할 수 있다는 증거를 쌓는 곳
- **상위 조직**: 늦깎이연구소
- **웹사이트**: https://choviet.chat

---

## 🧬 커널

```
장터 (실용)
    ↓
물건 뒤에 사람이 보인다 (연결)
    ↓
"나도 시작해볼까" (성장)
    ↓
커뮤니티가 된다
```

**핵심 질문**: "이 기능이 누군가에게 '나도 할 수 있겠다'는 욕망을 점화하는가?"

---

## 늦깎이연구소 vs Chợ Việt

| | 늦깎이연구소 | Chợ Việt |
|---|---|---|
| **타겟** | 늦게 시작한 사람들 | 타지에서 새 출발하는 사람들 |
| **진입점** | 블로그 (기록) | 장터 (거래) |
| **성장 방향** | 기술 × AI × 창작 | 소통 × 연결 × 자립 |
| **증거** | "50대가 앱을 만들었다" | "베트남 교민이 사업을 시작했다" |

---

## 현재 Phase: 0 (스토리 구조)

> 기능보다 먼저. 사람이 보이는 구조를 만든다.

### 0.1 판매자 스토리 섹션
- User 모델에 `story` 필드
- "어떻게 한국에 오게 됐나요?"
- 상품 상세에서 판매자 스토리 노출

### 0.2 첫 거래 기념 시스템
- "첫 판매 완료!" 배지
- 첫 거래 후 스토리 작성 유도

### 0.3 성장 기록 표시
- 거래 수, 활동 기간 표시
- 마일스톤 축하

### 0.4 스토리 피드
- 장터 탭 + 스토리 탭
- 물건이 아닌 사람을 발견

---

## 세션 시작 시

1. `ROADMAP.md` 확인
2. Phase 0 작업 중 다음 할 것 제안
3. 구현 전에 "이게 사람을 보이게 하는가?" 질문

---

## 기술 스택

- Backend: Ruby on Rails 8.0
- Database: SQLite (dev) / PostgreSQL (prod)
- Real-time: Redis + ActionCable
- Deploy: Kamal (AWS EC2)
- Domain: choviet.chat

---

## iOS/Android 앱

- **iOS**: `/Users/cezips/project/choviet-ios` (Turbo Native)
- **Android**: `/Users/cezips/project/choviet-android` (Turbo Native)
- **Bundle ID**: `cezips.choviet`
- 웹 변경 시 앱 재빌드 불필요 (웹뷰 기반)

### App Store Connect API

```bash
# 심사 상태 확인
~/.choviet/check_status.sh

# 또는 수동 실행
source ~/.choviet/appstore_api.env
cd /Users/cezips/project/choviet-ios && fastlane status
```

**설정 파일 위치**: `~/.choviet/`
- `appstore_api.env` - API 인증 정보
- `AuthKey_4427M88X6Q.p8` - API 키 파일
- `check_status.sh` - 상태 확인 스크립트

---

## 블로그 글 작성 시 주의

**Chợ Việt 개발 블로그 글의 독자는 베트남 교민이 아니다.**

독자는 늦깎이연구소 잠재 회원이다.
"나도 앱 만들 수 있을까?" 질문을 들고 온 사람이다.

글의 목적:
- ❌ "이렇게 하면 됩니다"
- ✅ "나도 무서웠는데, 해봤더니 됐다. 당신도 된다."

---

## 5년 후 (2031)

베트남에서 한국으로 막 온 사람이 검색한다.
"한국 베트남 커뮤니티"

Chợ Việt이 뜬다.

스크롤하면 이야기가 보인다.

"처음 왔을 때 한국어 하나도 못했어요.
장터에서 물건 팔면서 한국어 배웠어요.
지금은 작은 가게 열었어요."

**"아, 여기 사람들도 그랬구나. 나도 해볼까."**

---

*이 프로젝트는 기능이 아니라 사람을 중심으로 한다.*
