#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Chợ Việt Facebook Agent
주기적으로 Choviet의 인기 아이템을 Facebook에 홍보하는 에이전트

사용법:
  python3 facebook_agent.py              # 일반 실행 (1개 포스팅)
  python3 facebook_agent.py --batch 3    # 3개 포스팅
  python3 facebook_agent.py --dry-run    # 테스트 (실제 포스팅 안함)
"""

import os
import sys
import json
import random
import requests
import argparse
from datetime import datetime
from pathlib import Path

# Anthropic Claude API
try:
    import anthropic
except ImportError:
    print("❌ anthropic 패키지가 필요합니다: pip install anthropic")
    sys.exit(1)


class ChovietFacebookAgent:
    def __init__(self, config_path=None):
        self.config_path = config_path or Path(__file__).parent / "config.json"
        self.config = self._load_config()
        self.claude = anthropic.Anthropic(api_key=self.config.get("anthropic_api_key") or os.environ.get("ANTHROPIC_API_KEY"))

    def _load_config(self):
        """설정 파일 로드"""
        if not self.config_path.exists():
            print(f"❌ 설정 파일이 없습니다: {self.config_path}")
            print("   config_template.json을 복사하여 config.json을 만들어주세요.")
            sys.exit(1)

        with open(self.config_path, 'r', encoding='utf-8') as f:
            return json.load(f)

    def fetch_featured_posts(self, limit=5):
        """Choviet API에서 인기 아이템 조회"""
        api_url = self.config.get("choviet_api_url", "https://choviet.chat/api/v1/featured_posts/random")
        api_key = self.config.get("choviet_api_key")

        try:
            response = requests.get(
                api_url,
                params={"limit": limit},
                headers={"X-Api-Key": api_key},
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            return data.get("posts", [])
        except requests.RequestException as e:
            print(f"❌ API 호출 실패: {e}")
            return []

    def generate_promotional_text(self, post):
        """Claude API로 베트남어 홍보 문구 생성"""
        prompt = f"""Bạn là chuyên gia marketing cho cộng đồng người Việt tại Hàn Quốc.
Hãy viết một bài đăng Facebook ngắn gọn, hấp dẫn để quảng bá sản phẩm này.

Thông tin sản phẩm:
- Tiêu đề: {post['title']}
- Giá: {post['price_formatted']}
- Mô tả: {post.get('body', '')}
- Khu vực: {post.get('location', 'Hàn Quốc')}
- Người bán: {post['user']['name']} (độ tin cậy: {post['user']['reputation']}°)

Yêu cầu:
1. Viết bằng tiếng Việt, tự nhiên và thân thiện
2. Độ dài: 2-4 câu ngắn gọn
3. Thêm emoji phù hợp (1-3 emoji)
4. Kết thúc bằng lời kêu gọi hành động (xem chi tiết, liên hệ ngay, ...)
5. KHÔNG thêm hashtag
6. KHÔNG bịa thêm thông tin

Chỉ trả về nội dung bài đăng, không giải thích gì thêm."""

        try:
            response = self.claude.messages.create(
                model="claude-3-5-haiku-20241022",
                max_tokens=300,
                messages=[{"role": "user", "content": prompt}]
            )
            return response.content[0].text.strip()
        except Exception as e:
            print(f"⚠️ Claude API 오류: {e}")
            # Fallback: 기본 템플릿 사용
            return self._fallback_template(post)

    def _fallback_template(self, post):
        """Claude API 실패 시 기본 템플릿"""
        templates = [
            "🛒 {title}\n💰 Giá: {price}\n📍 {location}\n\n👉 Xem chi tiết tại Chợ Việt!",
            "✨ Sản phẩm mới trên Chợ Việt!\n\n{title}\n💵 {price} | 📍 {location}\n\nLiên hệ ngay!",
            "🔥 {title}\n\nGiá chỉ {price}!\n📍 Khu vực: {location}\n\n➡️ Nhấn xem ngay!"
        ]
        template = random.choice(templates)
        return template.format(
            title=post['title'],
            price=post['price_formatted'],
            location=post.get('location', 'Hàn Quốc')
        )

    def post_to_facebook(self, message, link, image_url=None, dry_run=False):
        """Facebook 페이지에 포스팅"""
        page_id = self.config.get("facebook_page_id")
        access_token = self.config.get("facebook_access_token")

        if not page_id or not access_token:
            print("❌ Facebook 설정이 없습니다 (page_id, access_token)")
            return None

        if dry_run:
            print("\n" + "="*50)
            print("🔍 [DRY RUN] 실제 포스팅하지 않음")
            print(f"📝 Message:\n{message}")
            print(f"🔗 Link: {link}")
            if image_url:
                print(f"🖼️ Image: {image_url}")
            print("="*50)
            return {"id": "dry_run_id", "dry_run": True}

        url = f"https://graph.facebook.com/v24.0/{page_id}/feed"

        data = {
            "message": message,
            "link": link,
            "access_token": access_token
        }

        try:
            response = requests.post(url, data=data, timeout=30)
            result = response.json()

            if "id" in result:
                post_id = result["id"]
                fb_url = f"https://www.facebook.com/{post_id.replace('_', '/posts/')}"
                print(f"✅ 포스팅 완료!")
                print(f"   Post ID: {post_id}")
                print(f"   URL: {fb_url}")
                return result
            else:
                print(f"❌ Facebook 오류: {result}")
                return None
        except requests.RequestException as e:
            print(f"❌ 요청 실패: {e}")
            return None

    def run(self, batch_size=1, dry_run=False):
        """에이전트 실행"""
        print(f"\n🚀 Chợ Việt Facebook Agent 시작")
        print(f"   시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"   배치 크기: {batch_size}")
        print(f"   Dry Run: {dry_run}")

        # 인기 아이템 조회
        posts = self.fetch_featured_posts(limit=batch_size)

        if not posts:
            print("⚠️ 조회된 아이템이 없습니다.")
            return []

        print(f"\n📦 {len(posts)}개 아이템 조회됨")

        results = []
        for i, post in enumerate(posts, 1):
            print(f"\n--- [{i}/{len(posts)}] {post['title'][:30]}... ---")

            # 홍보 문구 생성
            message = self.generate_promotional_text(post)
            print(f"📝 생성된 문구:\n{message[:100]}...")

            # Facebook 포스팅
            result = self.post_to_facebook(
                message=message,
                link=post['url'],
                image_url=post['images'][0] if post.get('images') else None,
                dry_run=dry_run
            )

            if result:
                results.append({
                    "post_id": post['id'],
                    "title": post['title'],
                    "facebook_result": result
                })

            # API 제한 방지
            if i < len(posts):
                import time
                time.sleep(3)

        print(f"\n✅ 완료: {len(results)}/{len(posts)}개 포스팅 성공")
        return results


def main():
    parser = argparse.ArgumentParser(description="Chợ Việt Facebook Agent")
    parser.add_argument("--batch", type=int, default=1, help="포스팅할 아이템 개수 (기본: 1)")
    parser.add_argument("--dry-run", action="store_true", help="테스트 모드 (실제 포스팅 안함)")
    parser.add_argument("--config", type=str, help="설정 파일 경로")

    args = parser.parse_args()

    config_path = Path(args.config) if args.config else None
    agent = ChovietFacebookAgent(config_path=config_path)
    agent.run(batch_size=args.batch, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
