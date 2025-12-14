# 📋 Chợ Việt 통합 테스트 가이드

## 🗂️ 테스트 파일 구조

```
test/integration/
├── scenario_1_new_user_test.rb        # 신규 유저 시나리오
├── scenario_2_first_trade_test.rb     # 첫 거래 시나리오
├── scenario_3_active_user_test.rb     # 활동 유저 시나리오
├── scenario_4_dormant_user_test.rb    # 휴면 유저 시나리오
├── scenario_5_anti_fraud_test.rb      # 사기 방지/신고 시나리오
└── scenario_6_ux_fade_test.rb         # UX Fade 종합 테스트
```

## 🚀 테스트 실행 방법

### 전체 통합 테스트 실행
```bash
# 모든 통합 테스트 실행
rails test test/integration/

# 또는
bin/rails test test/integration/
```

### 개별 시나리오 테스트
```bash
# 시나리오 1: 신규 유저
rails test test/integration/scenario_1_new_user_test.rb

# 시나리오 2: 첫 거래
rails test test/integration/scenario_2_first_trade_test.rb

# 시나리오 3: 활동 유저
rails test test/integration/scenario_3_active_user_test.rb

# 시나리오 4: 휴면 유저
rails test test/integration/scenario_4_dormant_user_test.rb

# 시나리오 5: 사기 방지
rails test test/integration/scenario_5_anti_fraud_test.rb

# 시나리오 6: UX Fade
rails test test/integration/scenario_6_ux_fade_test.rb
```

### 특정 테스트만 실행
```bash
# 특정 테스트 메서드 실행
rails test test/integration/scenario_1_new_user_test.rb -n test_new_user_can_access_their_profile_after_signup

# 패턴 매칭으로 실행
rails test test/integration/ -n /trust_summary/
```

## 📊 테스트 커버리지

### 시나리오 1: 신규 유저 (8 tests)
- [x] 회원가입 후 프로필 접근
- [x] 게시글 목록 노출
- [x] trust_summary 표시 (🌱 톤)
- [x] trust_hint 표시 (부드러운 제안)
- [x] CTA 버튼 우선 표시
- [x] 힌트가 버튼처럼 안보임
- [x] 금지 단어 미사용
- [x] first_trade? 검증

### 시나리오 2: 첫 거래 (10 tests)
- [x] 채팅 접근 가능
- [x] 거래 완료 버튼 동작
- [x] 시스템 메시지 표시
- [x] 리뷰 CTA 노출
- [x] 별점만으로 리뷰 제출
- [x] 코멘트 선택 사항
- [x] 보상 메시지 표시
- [x] trust_hint 사라짐
- [x] trust_summary 유지
- [x] 강제성 없는 UX

### 시나리오 3: 활동 유저 (8 tests)
- [x] trust_summary만 표시
- [x] trust_hint 미노출
- [x] 요약 한 줄 유지
- [x] 활동 이모지 사용
- [x] 간결한 채팅 UX
- [x] 정보 과잉 없음
- [x] 힌트 지속 안됨
- [x] 거래/활동 검증

### 시나리오 4: 휴면 유저 (9 tests)
- [x] 30일+ 비활동 확인
- [x] 🌙 이모지 표시
- [x] trust_hint 재등장
- [x] 경고 아닌 제안
- [x] 부담스럽지 않은 UX
- [x] 위험 단어 없음
- [x] 죄책감 유발 없음
- [x] 재활동 시 힌트 사라짐
- [x] 과거 평판 반영

### 시나리오 5: 사기 방지 (10 tests)
- [x] 신고 버튼 접근
- [x] 신고 사유 입력
- [x] 자동 시스템 메시지
- [x] 중복 메시지 방지
- [x] 저평판 경고 표시
- [x] 완전 차단 없음
- [x] 자연스러운 제한 UX
- [x] 명확한 이유 설명
- [x] 점진적 대응
- [x] 운영자 개입 느낌 없음

### 시나리오 6: UX Fade (9 tests)
- [x] 첫 거래 후 hint 사라짐
- [x] 활동 중 hint 없음
- [x] 휴면 시 hint 재등장
- [x] summary 항상 유지
- [x] 자연스러운 상태 전환
- [x] 이모지 일관성
- [x] UX 적절한 타이밍
- [x] Release Gate 테스트

## ✅ 성공 기준

모든 테스트가 통과하면:
```
54 runs, XX assertions, 0 failures, 0 errors
```

## 🔴 실패 시 확인사항

1. **데이터베이스 설정**
   ```bash
   rails db:test:prepare
   ```

2. **의존성 확인**
   ```bash
   bundle install
   ```

3. **마이그레이션 확인**
   ```bash
   rails db:migrate RAILS_ENV=test
   ```

## 📝 테스트 추가 가이드

새 테스트 추가 시:
1. 해당 시나리오 파일에 추가
2. `test "설명" do ... end` 형식 사용
3. 실패 신호도 테스트에 포함
4. 한글/베트남어 검증 포함

---

> 이 테스트는 **완벽을 증명하기 위한 것이 아니라,  
> 깨지기 전에 멈추기 위한 것**입니다.
