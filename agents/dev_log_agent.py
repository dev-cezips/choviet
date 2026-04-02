#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Chợ Việt 개발 로그 블로그 에이전트
=====================================
개발 과정을 늦깎이연구소 커널 철학에 맞춰 블로그 글로 변환

사용법:
    # 주제로 글 생성
    python3 dev_log_agent.py --topic "푸시 알림 구현"

    # git log 기반 글 생성
    python3 dev_log_agent.py --git-log 10

    # 세션 요약 파일 기반
    python3 dev_log_agent.py --session /path/to/session_summary.md

    # 생성 후 바로 발행
    python3 dev_log_agent.py --topic "로그인 기능" --publish

    # 시리즈 번호 지정
    python3 dev_log_agent.py --topic "Rails 시작하기" --series 2

출력:
    ./drafts/YYYYMMDD_slug/
    ├── post.md          # 블로그 본문
    └── meta.yaml        # 메타 정보
"""

import os
import sys
import json
import re
import argparse
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List

try:
    import anthropic
except ImportError:
    print("❌ anthropic 패키지가 필요합니다: pip install anthropic")
    sys.exit(1)


# ========== 커널 철학 가이드라인 ==========

KERNEL_GUIDELINES = """
## 늦깎이연구소 콘텐츠 커널

### 핵심 철학
- 성찰(Reflection) → 믿음(Belief) → 욕망(Desire)
- 기록 → 연결 → 성장

### 5대 키워드
1. 다시 시작 - 늦었지만 새로 시작하는 용기
2. 성장 - 작은 발전도 의미있는 성장
3. 가족 - 가족을 위한 마음
4. 연결 - 같은 처지의 사람들과 연결
5. 기회 - 새로운 기회 발견

### 숨겨진 키워드
"포기 안 함" - 매 글에 이 정신이 담겨야 함

### 글의 구조 (필수)

1. **성찰 (왜 이걸 하게 됐나)** - 30%
   - 개인적 계기, 고민, 실패담
   - "나도 처음엔 몰랐다", "막막했다"
   - 독자가 공감할 수 있는 시작점

2. **과정 (어떻게 해결했나)** - 50%
   - 시행착오 솔직하게 포함
   - AI(Claude) 도움 받은 부분 명시
   - 비전공자도 따라할 수 있게 설명
   - 코드는 핵심만, 장황하지 않게

3. **성장 (무엇을 얻었나)** - 20%
   - 기술적 성과 + 내면의 변화
   - 다음 도전으로 연결
   - "당신도 할 수 있다" 메시지

### 톤앤매너
- 짧은 문장 위주 (한 문장에 하나의 생각)
- 전문용어는 괄호로 설명 추가
- 1인칭 시점으로 친근하게
- 겸손하지만 자기비하는 NO
- 이모지 최소화 (제목에 1개 정도)

### 금지사항
- 과도한 기술 자랑
- "쉽다", "간단하다" 같은 표현 (독자에겐 어려울 수 있음)
- 정답을 아는 척하는 태도
- 추상적인 조언만 나열

### 시리즈 제목 형식
[혼자서 앱 만들기 #N] 부제목
"""

BLOG_PROMPT_TEMPLATE = """당신은 늦깎이연구소의 블로그 작가입니다.
40대에 개발을 시작한 비전공자가 AI의 도움을 받아 앱을 만들어가는 과정을 기록합니다.

{kernel_guidelines}

---

## 작성 요청

**프로젝트**: Chợ Việt (쵸비엣) - 한국 거주 베트남인 커뮤니티 앱
**시리즈 번호**: {series_number}
**주제**: {topic}

{context}

---

## 출력 형식

다음 형식으로 블로그 글을 작성해주세요:

```markdown
---
title: "[혼자서 앱 만들기 #{series_number}] 여기에 제목"
category: choviet
tags: 태그1, 태그2, 태그3, 늦깎이, 앱개발
excerpt: SEO용 요약 (2-3문장)
---

본문 내용...
```

본문은 1500-2500자 사이로 작성해주세요.
마크다운 형식을 사용하되, 코드 블록은 핵심만 간결하게 포함하세요.
"""


class DevLogAgent:
    """개발 로그 블로그 에이전트"""

    def __init__(self, config_path: Optional[Path] = None):
        self.config_path = config_path or Path(__file__).parent / "config.json"
        self.config = self._load_config()
        self.claude = anthropic.Anthropic(
            api_key=self.config.get("anthropic_api_key") or os.environ.get("ANTHROPIC_API_KEY")
        )
        self.drafts_dir = Path(__file__).parent / "drafts"
        self.drafts_dir.mkdir(exist_ok=True)

    def _load_config(self) -> dict:
        """설정 로드"""
        if self.config_path.exists():
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}

    def get_git_log(self, count: int = 10) -> str:
        """최근 git 커밋 로그 가져오기"""
        try:
            result = subprocess.run(
                ["git", "log", f"-{count}", "--pretty=format:%h %s (%ar)", "--no-merges"],
                cwd=Path(__file__).parent.parent,  # choviet 루트
                capture_output=True,
                text=True
            )
            return result.stdout
        except Exception as e:
            return f"Git 로그 조회 실패: {e}"

    def get_recent_changes(self, days: int = 7) -> str:
        """최근 변경 요약"""
        try:
            result = subprocess.run(
                ["git", "log", f"--since={days} days ago", "--pretty=format:- %s", "--no-merges"],
                cwd=Path(__file__).parent.parent,
                capture_output=True,
                text=True
            )
            return result.stdout
        except Exception as e:
            return f"변경 내역 조회 실패: {e}"

    def generate_blog_post(
        self,
        topic: str,
        series_number: int = 1,
        context: str = "",
        git_context: bool = False
    ) -> Dict:
        """블로그 글 생성"""

        # Git 컨텍스트 추가
        if git_context:
            git_log = self.get_git_log(20)
            context += f"\n\n### 최근 Git 커밋\n```\n{git_log}\n```"

        prompt = BLOG_PROMPT_TEMPLATE.format(
            kernel_guidelines=KERNEL_GUIDELINES,
            series_number=series_number,
            topic=topic,
            context=context if context else "추가 컨텍스트 없음"
        )

        print(f"📝 글 생성 중: {topic}")
        print(f"   시리즈 #{series_number}")

        try:
            response = self.claude.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=4000,
                messages=[{"role": "user", "content": prompt}]
            )

            content = response.content[0].text

            # 마크다운 코드 블록 추출
            md_match = re.search(r'```markdown\s*(.*?)```', content, re.DOTALL)
            if md_match:
                markdown_content = md_match.group(1).strip()
            else:
                markdown_content = content

            return {
                "success": True,
                "content": markdown_content,
                "raw_response": content
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

    def save_draft(self, content: str, topic: str) -> Path:
        """초안 저장"""
        # 슬러그 생성
        slug = re.sub(r'[^\w\s-]', '', topic.lower())
        slug = re.sub(r'[\s_]+', '-', slug)[:50]

        # 폴더 생성
        date_str = datetime.now().strftime('%Y%m%d')
        folder_name = f"{date_str}_{slug}"
        folder_path = self.drafts_dir / folder_name
        folder_path.mkdir(exist_ok=True)

        # post.md 저장
        post_path = folder_path / "post.md"
        with open(post_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"💾 저장됨: {post_path}")
        return folder_path

    def publish(self, folder_path: Path) -> Optional[str]:
        """lbl-wordpress publish.py로 발행"""
        publish_script = Path(__file__).parent.parent.parent / "lbl-wordpress" / "blog_agent" / "publish.py"

        if not publish_script.exists():
            print(f"❌ publish.py를 찾을 수 없습니다: {publish_script}")
            return None

        try:
            result = subprocess.run(
                ["python3", str(publish_script), str(folder_path)],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                # URL 추출
                url_match = re.search(r'URL:\s*(https?://\S+)', result.stdout)
                if url_match:
                    return url_match.group(1)

            print(f"발행 출력:\n{result.stdout}")
            if result.stderr:
                print(f"에러:\n{result.stderr}")

            return None

        except Exception as e:
            print(f"❌ 발행 실패: {e}")
            return None

    def run(
        self,
        topic: str,
        series_number: int = 1,
        context: str = "",
        git_context: bool = False,
        auto_publish: bool = False
    ) -> Dict:
        """에이전트 실행"""

        print("\n" + "=" * 50)
        print("🚀 Chợ Việt 개발 로그 에이전트")
        print(f"   시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 50)

        # 1. 글 생성
        result = self.generate_blog_post(
            topic=topic,
            series_number=series_number,
            context=context,
            git_context=git_context
        )

        if not result["success"]:
            print(f"❌ 생성 실패: {result['error']}")
            return result

        # 2. 초안 저장
        folder_path = self.save_draft(result["content"], topic)
        result["draft_path"] = str(folder_path)

        # 3. 발행 (선택)
        if auto_publish:
            print("\n📤 WordPress 발행 중...")
            url = self.publish(folder_path)
            if url:
                result["published_url"] = url
                print(f"✅ 발행 완료: {url}")
            else:
                print("⚠️ 발행 실패 - 초안은 저장됨")

        print("\n" + "=" * 50)
        print("✅ 완료!")
        print(f"   초안: {folder_path}/post.md")
        if "published_url" in result:
            print(f"   URL: {result['published_url']}")
        print("=" * 50)

        return result


def main():
    parser = argparse.ArgumentParser(
        description="Chợ Việt 개발 로그 블로그 에이전트",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
예시:
  python3 dev_log_agent.py --topic "푸시 알림 구현기"
  python3 dev_log_agent.py --topic "Rails 시작" --series 1 --publish
  python3 dev_log_agent.py --topic "로그인 삽질" --git
        """
    )

    parser.add_argument("--topic", "-t", required=True, help="블로그 주제")
    parser.add_argument("--series", "-s", type=int, default=1, help="시리즈 번호 (기본: 1)")
    parser.add_argument("--context", "-c", help="추가 컨텍스트 텍스트")
    parser.add_argument("--context-file", help="추가 컨텍스트 파일 경로")
    parser.add_argument("--git", action="store_true", help="Git 로그를 컨텍스트에 포함")
    parser.add_argument("--publish", "-p", action="store_true", help="생성 후 바로 발행")
    parser.add_argument("--config", help="설정 파일 경로")

    args = parser.parse_args()

    # 컨텍스트 처리
    context = args.context or ""
    if args.context_file:
        try:
            with open(args.context_file, 'r', encoding='utf-8') as f:
                context += "\n\n" + f.read()
        except Exception as e:
            print(f"⚠️ 컨텍스트 파일 읽기 실패: {e}")

    # 에이전트 실행
    config_path = Path(args.config) if args.config else None
    agent = DevLogAgent(config_path=config_path)

    result = agent.run(
        topic=args.topic,
        series_number=args.series,
        context=context,
        git_context=args.git,
        auto_publish=args.publish
    )

    if not result.get("success"):
        sys.exit(1)


if __name__ == "__main__":
    main()
