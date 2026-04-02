# Chợ Việt Agents

Choviet 자동화 에이전트 모음

```
agents/
├── roadmap_agent.py      # 🔴 로드맵 자동 실행 (핵심)
├── dev_log_agent.py      # 개발 로그 → 블로그 글
├── facebook_agent.py     # 아이템 → Facebook 홍보
├── config.json           # 설정 (git ignored)
├── config_template.json  # 설정 템플릿
└── drafts/               # 블로그 초안 저장
```

---

## Roadmap Agent (로드맵 자동 실행)

ROADMAP.md의 자동화 가능 작업(🤖)을 순차적으로 실행

### 작동 방식

```
1. ROADMAP.md 파싱
2. 다음 자동화 가능 작업 선택
3. Claude API로 분석 + 구현
4. 별도 브랜치에 커밋
5. ROADMAP.md 업데이트 (체크 표시)
6. 푸시 → PR 대기
```

### 사용법

```bash
# 다음 작업 1개 실행 (dry-run)
python3 roadmap_agent.py --dry-run

# 실제 실행
python3 roadmap_agent.py

# 3개 작업 연속 실행
python3 roadmap_agent.py --count 3

# 특정 작업만 실행
python3 roadmap_agent.py --task "온보딩 플로우"

# PR까지 자동 생성
python3 roadmap_agent.py --count 2 --pr
```

### A/B 하이브리드 운영

```
┌─────────────────────────────────────────────┐
│ Option A: 사람이 있을 때 (Claude Code)      │
│   → 복잡한 작업, 의사결정, 즉시 반영        │
├─────────────────────────────────────────────┤
│ Option B: 사람이 없을 때 (Cron)             │
│   → 단순 작업, PR로 생성, 나중에 리뷰       │
└─────────────────────────────────────────────┘

충돌 방지:
- B는 항상 별도 브랜치 (auto/YYYYMMDD-HHMM)
- B는 PR만 생성, 머지는 사람이
- A가 먼저 main에서 작업
```

### Cron 설정

```bash
# 매일 오전 9시 자동 실행 (2개 작업)
0 9 * * * cd /Users/cezips/project/choviet/agents && python3 roadmap_agent.py --count 2 >> ~/logs/roadmap.log 2>&1
```

### 출력 예시

```
🤖 Chợ Việt Roadmap Agent
   시간: 2026-04-02 09:00:00
   모드: Execute

📋 로드맵 파싱 완료: 45개 작업

🎯 실행할 작업: 2개
   - 온보딩 플로우 UI
   - 언어 선택 화면

🌿 브랜치 생성: auto/20260402-0900

────────────────────────────────────────
📌 작업: 온보딩 플로우 UI
   Phase: Phase 1: 출시 준비 (65% → 75%)
   🔍 분석 중...
   📊 복잡도: medium
   📁 예상 파일: app/views/onboarding/, app/controllers/onboarding_controller.rb
   ⚙️ 실행 중...
   📝 app/controllers/onboarding_controller.rb
   📝 app/views/onboarding/index.html.erb
   ✅ 완료!
   💾 커밋 완료

📊 결과: 2/2 작업 완료
🌿 브랜치: auto/20260402-0900
   → PR 생성 후 리뷰해주세요
```

---

---

## Dev Log Agent (개발 로그 블로그)

개발 과정을 늦깎이연구소 커널 철학에 맞춰 블로그 글로 변환

### 커널 철학 적용

```
성찰 (30%) → 과정 (50%) → 성장 (20%)
   ↓           ↓            ↓
 왜 했나    어떻게 했나   무엇을 얻었나
```

### 사용법

```bash
# 주제로 글 생성
python3 dev_log_agent.py --topic "푸시 알림 구현"

# 시리즈 번호 지정
python3 dev_log_agent.py --topic "Rails 시작하기" --series 2

# Git 로그를 컨텍스트로 포함
python3 dev_log_agent.py --topic "이번 주 작업" --git

# 추가 컨텍스트 파일 제공
python3 dev_log_agent.py --topic "로그인 기능" --context-file ./notes.md

# 생성 후 바로 WordPress 발행
python3 dev_log_agent.py --topic "앱스토어 심사" --series 5 --publish
```

### 출력 구조

```
drafts/
└── 20260402_푸시-알림-구현/
    └── post.md
```

### post.md 예시

```markdown
---
title: "[혼자서 앱 만들기 #4] 푸시 알림, 생각보다 복잡했다"
category: choviet
tags: 푸시알림, FCM, Rails, 늦깎이, 앱개발
excerpt: 40대 비전공자가 푸시 알림을 구현하며 겪은 시행착오와 배움
---

## 왜 푸시 알림이 필요했나

채팅 기능을 만들고 나니 문제가 생겼다...
```

### lbl-wordpress 연동

생성된 초안은 lbl-wordpress의 `publish.py`로 발행:

```bash
# 자동 발행 (--publish 플래그)
python3 dev_log_agent.py --topic "주제" --publish

# 또는 수동 발행
python3 /Users/cezips/project/lbl-wordpress/blog_agent/publish.py ./drafts/20260402_주제/
```

---

## Facebook Agent

주기적으로 Choviet의 인기 아이템을 Facebook 페이지에 홍보하는 에이전트

### 설치

```bash
cd /Users/cezips/project/choviet/agents
pip install anthropic requests
```

### 설정

1. 설정 파일 생성:
```bash
cp config_template.json config.json
```

2. config.json 수정:
```json
{
  "choviet_api_key": "Rails credentials에서 생성한 키",
  "facebook_page_id": "Facebook 페이지 ID",
  "facebook_access_token": "페이지 액세스 토큰",
  "anthropic_api_key": "Claude API 키 (또는 ANTHROPIC_API_KEY 환경변수)"
}
```

### Choviet API 키 설정

Rails credentials에 추가:
```bash
cd /Users/cezips/project/choviet
EDITOR="code --wait" bin/rails credentials:edit
```

```yaml
api:
  agent_key: "랜덤한_시크릿_키_생성"
```

또는 환경변수:
```bash
export CHOVIET_AGENT_API_KEY="your_secret_key"
```

### Facebook 토큰 발급

lbl-wordpress의 가이드 참조:
```
/Users/cezips/project/lbl-wordpress/facebook/README.md
```

### 사용법

```bash
# 단일 포스팅
python3 facebook_agent.py

# 3개 아이템 포스팅
python3 facebook_agent.py --batch 3

# 테스트 (실제 포스팅 안함)
python3 facebook_agent.py --dry-run

# 설정 파일 지정
python3 facebook_agent.py --config /path/to/config.json
```

### Cron 설정

매일 오전 10시, 오후 6시 자동 실행:

```bash
crontab -e
```

```cron
# Choviet Facebook Agent
0 10 * * * cd /Users/cezips/project/choviet/agents && /usr/bin/python3 facebook_agent.py >> /var/log/choviet_fb.log 2>&1
0 18 * * * cd /Users/cezips/project/choviet/agents && /usr/bin/python3 facebook_agent.py >> /var/log/choviet_fb.log 2>&1
```

### 포스팅 예시

```
🛒 iPhone 14 Pro còn bảo hành
💰 Giá: 800,000₩
📍 Ansan

Máy đẹp, không trầy xước. Còn bảo hành Apple Care đến tháng 12.
Ai quan tâm inbox ngay nhé! 👉

[Link to choviet.chat/posts/123]
```

## 향후 에이전트 계획

- [ ] Instagram Agent
- [ ] Zalo Agent
- [ ] Newsletter Agent
