---
title: "[혼자서 앱 만들기 #6] 구글 로그인, 생각보다 쉬웠다"
category: Choviet
tags: OAuth, 소셜로그인, Google, 온보딩, Rails, Devise, 늦깎이, 앱개발
excerpt: 50대 비전공자가 구글 소셜 로그인과 온보딩 플로우를 하루 만에 구현한 이야기
---

## 왜 소셜 로그인이 필요했나

Chợ Việt을 만들면서 가장 많이 받은 피드백이 있다.

> "회원가입이 귀찮아요"

맞는 말이다. 이메일 입력하고, 비밀번호 만들고, 또 확인하고... 2026년에 이런 과정을 거치는 게 오히려 이상하다. 당근마켓도, 번개장터도 전부 소셜 로그인을 지원한다.

베트남 커뮤니티 앱이라면 더욱 그렇다. 한국에 온 지 얼마 안 된 분들이 복잡한 회원가입 절차를 거치면서까지 앱을 쓸까?

**진입 장벽을 낮춰야 했다.**

그리고 또 하나. 신규 가입자가 앱에 들어왔을 때 "이게 뭐하는 앱이지?" 하고 이탈하는 경우가 많았다. 언어 설정도, 지역 설정도 나중에 프로필에서 해야 했다.

**첫 경험을 안내해야 했다.**

![로그인 페이지에 추가된 Google 버튼](01-login-page.png)
*로그인 페이지 - Google 로그인 버튼이 추가됐다*

---

## 구글 로그인 구현하기

### Devise + OmniAuth 조합

Rails에서 인증은 Devise가 표준이다. 여기에 OmniAuth를 붙이면 소셜 로그인이 가능해진다.

```ruby
# Gemfile
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-google-oauth2", "~> 1.2"
gem "omniauth-apple", "~> 1.4"
```

처음엔 카카오 로그인도 넣으려 했는데, `omniauth-kakao` 젬이 OmniAuth 2.x와 호환이 안 됐다. 일단 구글과 애플만 먼저 구현하기로 했다.

### Google Cloud Console 설정

의외로 시간이 걸린 건 코드가 아니라 Google Cloud Console 설정이었다.

1. 프로젝트 생성
2. OAuth 동의 화면 설정
3. **웹 애플리케이션** 타입으로 클라이언트 ID 생성
4. 리디렉션 URI 등록

처음에 "데스크톱" 타입으로 만들어서 에러가 났다. **반드시 "웹 애플리케이션"**으로 만들어야 한다.

```
http://localhost:3000/users/auth/google_oauth2/callback
http://localhost:3004/users/auth/google_oauth2/callback
https://choviet.chat/users/auth/google_oauth2/callback
```

개발 환경 포트가 3000일 수도 있고 3004일 수도 있어서 둘 다 등록했다.

### User 모델 수정

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2, :apple]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
    end
  end

  def password_required?
    provider.blank? && super
  end
end
```

`from_omniauth` 메서드가 핵심이다. OAuth로 받아온 정보로 유저를 찾거나 생성한다. `password_required?`를 오버라이드해서 소셜 로그인 유저는 비밀번호 없이도 가입할 수 있게 했다.

### 콜백 컨트롤러

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth("Google")
  end

  private

  def handle_auth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in @user, event: :authentication

      if @user.needs_onboarding?
        redirect_to onboarding_path
      else
        redirect_to root_path
      end
    else
      redirect_to new_user_registration_url
    end
  end
end
```

신규 가입자는 온보딩으로, 기존 유저는 메인 피드로 보낸다.

---

## 온보딩 플로우 만들기

### 3단계 설계

1. **언어 선택** - 베트남어, 한국어, 영어
2. **지역 선택** - 서울, 경기, 인천, 부산 등
3. **환영 & 기능 소개** - 앱이 뭘 할 수 있는지 안내

![온보딩 1단계: 언어 선택](03-onboarding-language.png)
*온보딩 첫 화면 - 베트남어, 한국어, 영어 중 선택*

```ruby
class OnboardingController < ApplicationController
  before_action :authenticate_user!

  def show
    @step = determine_current_step
    render_step(@step)
  end

  def update
    case params[:step].to_i
    when 1
      current_user.update(locale: params[:locale])
      redirect_to onboarding_path(step: 2)
    when 2
      current_user.update(location_code: params[:location_code])
      redirect_to onboarding_path(step: 3)
    when 3
      current_user.update(onboarding_completed: true)
      redirect_to root_path
    end
  end
end
```

### UI는 심플하게

```erb
<!-- 언어 선택 -->
<label class="block cursor-pointer">
  <input type="radio" name="locale" value="vi" class="peer hidden">
  <div class="flex items-center p-4 border-2 rounded-lg
              peer-checked:border-blue-500 peer-checked:bg-blue-50">
    <span class="text-3xl mr-4">🇻🇳</span>
    <div>Tiếng Việt</div>
  </div>
</label>
```

Tailwind CSS의 `peer` 기능을 활용했다. 라디오 버튼을 숨기고, 선택되면 카드 전체가 하이라이트된다.

---

## 배포하고 확인하기

```bash
git add -A
git commit -m "feat: add social login (Google OAuth) and onboarding flow"
git push origin main
kamal deploy
```

Kamal 덕분에 배포는 2분이면 끝난다.

```bash
kamal app exec -i --reuse "bin/rails db:migrate"
```

프로덕션 DB 마이그레이션도 한 줄이면 된다.

**https://choviet.chat** 에서 구글 로그인이 잘 작동하는 걸 확인했다.

---

## 무엇을 얻었나

### 기술적 성장

- **OmniAuth 2.x** 사용법을 익혔다
- **Google Cloud Console** OAuth 설정 경험
- **Devise**와 **OmniAuth** 통합 패턴 이해
- **온보딩 플로우** 설계 및 구현

### 제품적 성장

- 회원가입 진입장벽 대폭 낮춤
- 신규 유저 첫 경험 개선
- 언어/지역 설정을 자연스럽게 유도

### 깨달은 것

처음엔 "소셜 로그인은 복잡하겠지"라고 생각했다. OAuth 스펙 문서를 봐야 하나, 토큰 관리는 어떻게 하나...

막상 해보니 **Devise + OmniAuth 조합이 대부분을 처리**해준다. 내가 할 건 Google Cloud Console 설정하고, 콜백 컨트롤러 만드는 것뿐이었다.

> "어려워 보이는 것도 일단 시작하면 길이 보인다."

늦깎이 개발의 핵심은 **완벽하게 이해하고 시작하는 게 아니라, 일단 해보면서 배우는 것**이다.

---

## 다음 할 일

- [ ] Apple Sign In 구현 (인증서 설정 필요)
- [ ] 카카오 로그인 (별도 구현 필요)
- [ ] 프로덕션에서 실제 유저 테스트

---

*이 글은 [혼자서 앱 만들기] 시리즈의 6번째 글입니다.*
*Chợ Việt: 한국의 베트남 커뮤니티를 위한 중고거래 앱*
