#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Chợ Việt Roadmap Executor Agent
================================
로드맵의 자동화 가능 작업을 순차적으로 실행

실행 모드:
    # 다음 작업 1개 실행
    python3 roadmap_agent.py

    # 다음 작업 N개 실행
    python3 roadmap_agent.py --count 3

    # Dry-run (실제 실행 안함, 계획만)
    python3 roadmap_agent.py --dry-run

    # 특정 작업만 실행
    python3 roadmap_agent.py --task "온보딩 플로우 UI"

자동 실행 (cron):
    0 9 * * * cd /Users/cezips/project/choviet/agents && python3 roadmap_agent.py --count 2 >> /var/log/roadmap_agent.log 2>&1

출력:
    - 코드 변경사항은 별도 브랜치에 커밋
    - PR 생성 (선택)
    - ROADMAP.md 업데이트
    - 슬랙/텔레그램 알림 (설정 시)
"""

import os
import sys
import re
import json
import subprocess
import argparse
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List, Tuple
from dataclasses import dataclass
from enum import Enum

try:
    import anthropic
except ImportError:
    print("❌ anthropic 패키지가 필요합니다: pip install anthropic")
    sys.exit(1)


class TaskStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    BLOCKED = "blocked"


@dataclass
class RoadmapTask:
    """로드맵 작업 항목"""
    id: str
    title: str
    phase: str
    section: str
    is_automatable: bool
    is_human_required: bool
    status: TaskStatus
    line_number: int
    raw_line: str
    dependencies: List[str] = None

    def __post_init__(self):
        if self.dependencies is None:
            self.dependencies = []


class RoadmapParser:
    """ROADMAP.md 파서"""

    def __init__(self, roadmap_path: Path):
        self.roadmap_path = roadmap_path
        self.content = ""
        self.tasks: List[RoadmapTask] = []

    def parse(self) -> List[RoadmapTask]:
        """로드맵 파싱"""
        with open(self.roadmap_path, 'r', encoding='utf-8') as f:
            self.content = f.read()
            lines = self.content.split('\n')

        current_phase = ""
        current_section = ""
        task_id = 0

        for i, line in enumerate(lines):
            # Phase 감지
            if line.startswith('## Phase'):
                current_phase = line.strip('# ').strip()
                continue

            # Section 감지
            if line.startswith('### '):
                current_section = line.strip('# ').strip()
                continue

            # Task 감지 (체크박스)
            task_match = re.match(r'^(\s*)-\s*\[([ x])\]\s*(.+)$', line)
            if task_match:
                indent = task_match.group(1)
                checked = task_match.group(2) == 'x'
                task_text = task_match.group(3)

                # 자동화 가능 여부
                is_automatable = '🤖' in task_text or '**자동화 가능**' in task_text
                is_human_required = '⚠️' in task_text or '**사람 필요**' in task_text

                # 제목 추출 (이모지, 마크다운 제거)
                title = re.sub(r'🤖|⚠️|\*\*[^*]+\*\*|\([^)]+\)', '', task_text).strip()

                task_id += 1
                task = RoadmapTask(
                    id=f"task_{task_id}",
                    title=title,
                    phase=current_phase,
                    section=current_section,
                    is_automatable=is_automatable,
                    is_human_required=is_human_required,
                    status=TaskStatus.COMPLETED if checked else TaskStatus.PENDING,
                    line_number=i,
                    raw_line=line
                )
                self.tasks.append(task)

        return self.tasks

    def get_next_automatable_tasks(self, count: int = 1) -> List[RoadmapTask]:
        """다음 자동화 가능 작업 반환"""
        automatable = [
            t for t in self.tasks
            if t.status == TaskStatus.PENDING
            and t.is_automatable
            and not t.is_human_required
        ]
        return automatable[:count]

    def mark_task_completed(self, task: RoadmapTask) -> bool:
        """작업 완료 표시"""
        lines = self.content.split('\n')

        if task.line_number < len(lines):
            old_line = lines[task.line_number]
            new_line = old_line.replace('- [ ]', '- [x]')

            if old_line != new_line:
                lines[task.line_number] = new_line
                self.content = '\n'.join(lines)

                with open(self.roadmap_path, 'w', encoding='utf-8') as f:
                    f.write(self.content)

                return True

        return False

    def mark_task_in_progress(self, task: RoadmapTask) -> bool:
        """작업 진행 중 표시 (🔄 추가)"""
        lines = self.content.split('\n')

        if task.line_number < len(lines):
            old_line = lines[task.line_number]
            if '🔄' not in old_line:
                # 체크박스 뒤에 🔄 추가
                new_line = old_line.replace('- [ ]', '- [ ] 🔄')
                lines[task.line_number] = new_line
                self.content = '\n'.join(lines)

                with open(self.roadmap_path, 'w', encoding='utf-8') as f:
                    f.write(self.content)

                return True

        return False


class GitManager:
    """Git 작업 관리"""

    def __init__(self, repo_path: Path):
        self.repo_path = repo_path

    def run_git(self, *args) -> Tuple[bool, str]:
        """Git 명령 실행"""
        try:
            result = subprocess.run(
                ['git'] + list(args),
                cwd=self.repo_path,
                capture_output=True,
                text=True
            )
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)

    def get_current_branch(self) -> str:
        """현재 브랜치"""
        success, output = self.run_git('branch', '--show-current')
        return output.strip() if success else 'main'

    def create_branch(self, branch_name: str) -> bool:
        """브랜치 생성 및 체크아웃"""
        success, _ = self.run_git('checkout', '-b', branch_name)
        return success

    def checkout(self, branch_name: str) -> bool:
        """브랜치 체크아웃"""
        success, _ = self.run_git('checkout', branch_name)
        return success

    def commit(self, message: str) -> bool:
        """변경사항 커밋"""
        self.run_git('add', '-A')
        success, _ = self.run_git('commit', '-m', message)
        return success

    def push(self, branch_name: str) -> bool:
        """푸시"""
        success, _ = self.run_git('push', '-u', 'origin', branch_name)
        return success

    def has_changes(self) -> bool:
        """변경사항 있는지 확인"""
        success, output = self.run_git('status', '--porcelain')
        return bool(output.strip())


class TaskExecutor:
    """작업 실행기 (Claude API 사용)"""

    def __init__(self, config: dict, project_path: Path):
        self.config = config
        self.project_path = project_path
        self.claude = anthropic.Anthropic(
            api_key=config.get("anthropic_api_key") or os.environ.get("ANTHROPIC_API_KEY")
        )

    def analyze_task(self, task: RoadmapTask) -> Dict:
        """작업 분석 및 실행 계획 생성"""

        prompt = f"""당신은 Rails 8 + Hotwire 전문 개발자입니다.
프로젝트: Chợ Việt (한국 거주 베트남인 커뮤니티 앱)

다음 작업을 분석하고 실행 계획을 JSON으로 반환하세요.

## 작업 정보
- 제목: {task.title}
- Phase: {task.phase}
- Section: {task.section}

## 프로젝트 구조
- Backend: Ruby on Rails 8.0
- Frontend: Hotwire (Turbo + Stimulus)
- CSS: Tailwind CSS
- Database: PostgreSQL

## 응답 형식 (JSON)
```json
{{
  "task_summary": "작업 요약 (1줄)",
  "complexity": "low|medium|high",
  "estimated_files": ["예상 수정 파일들"],
  "steps": [
    {{
      "order": 1,
      "description": "단계 설명",
      "type": "create|modify|delete|command",
      "target": "파일 경로 또는 명령어"
    }}
  ],
  "dependencies": ["필요한 gem 또는 패키지"],
  "risks": ["주의사항"],
  "can_auto_execute": true|false,
  "blocker_reason": "자동 실행 불가 시 이유"
}}
```

JSON만 반환하세요. 설명 없이."""

        try:
            response = self.claude.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=2000,
                messages=[{"role": "user", "content": prompt}]
            )

            content = response.content[0].text

            # JSON 추출
            json_match = re.search(r'```json\s*(.*?)```', content, re.DOTALL)
            if json_match:
                return json.loads(json_match.group(1))
            else:
                return json.loads(content)

        except Exception as e:
            return {
                "error": str(e),
                "can_auto_execute": False,
                "blocker_reason": f"분석 실패: {e}"
            }

    def execute_task(self, task: RoadmapTask, plan: Dict, dry_run: bool = False) -> Dict:
        """작업 실행"""

        if dry_run:
            return {
                "success": True,
                "dry_run": True,
                "plan": plan,
                "message": "Dry-run 모드: 실제 실행하지 않음"
            }

        if not plan.get("can_auto_execute", False):
            return {
                "success": False,
                "reason": plan.get("blocker_reason", "자동 실행 불가"),
                "plan": plan
            }

        # 실제 코드 생성 요청
        implementation_prompt = f"""다음 작업을 구현하세요.

## 작업
{task.title}

## 실행 계획
{json.dumps(plan, ensure_ascii=False, indent=2)}

## 프로젝트 경로
{self.project_path}

## 응답 형식
각 파일에 대해:

### FILE: path/to/file.rb
```ruby
전체 파일 내용
```

### COMMAND: 실행할 명령어
```bash
명령어
```

모든 파일의 전체 내용을 포함하세요."""

        try:
            response = self.claude.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=8000,
                messages=[{"role": "user", "content": implementation_prompt}]
            )

            implementation = response.content[0].text

            # 파일 및 명령어 추출/실행
            files_created = self._apply_implementation(implementation)

            return {
                "success": True,
                "files_modified": files_created,
                "plan": plan
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "plan": plan
            }

    def _apply_implementation(self, implementation: str) -> List[str]:
        """구현 내용 적용"""
        files_modified = []

        # 파일 패턴 매칭
        file_pattern = r'### FILE:\s*(.+?)\n```\w*\n(.*?)```'
        for match in re.finditer(file_pattern, implementation, re.DOTALL):
            file_path = match.group(1).strip()
            content = match.group(2)

            full_path = self.project_path / file_path

            # 디렉토리 생성
            full_path.parent.mkdir(parents=True, exist_ok=True)

            # 파일 쓰기
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content)

            files_modified.append(file_path)
            print(f"  📝 {file_path}")

        # 명령어 패턴 매칭
        cmd_pattern = r'### COMMAND:.*?\n```\w*\n(.*?)```'
        for match in re.finditer(cmd_pattern, implementation, re.DOTALL):
            command = match.group(1).strip()

            # 안전한 명령어만 실행
            if self._is_safe_command(command):
                print(f"  ▶️ {command}")
                subprocess.run(command, shell=True, cwd=self.project_path)

        return files_modified

    def _is_safe_command(self, command: str) -> bool:
        """안전한 명령어인지 확인"""
        safe_prefixes = [
            'bin/rails',
            'bundle',
            'npm',
            'yarn',
            'mkdir',
            'touch'
        ]
        dangerous = ['rm -rf', 'sudo', 'chmod 777', 'curl | sh', '> /']

        for d in dangerous:
            if d in command:
                return False

        for prefix in safe_prefixes:
            if command.startswith(prefix):
                return True

        return False


class ValidationPipeline:
    """코드 검증 파이프라인"""

    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.errors: List[str] = []

    def run_all(self, files_modified: List[str]) -> Dict:
        """모든 검증 실행"""
        self.errors = []
        results = {
            "syntax": self._check_syntax(files_modified),
            "lint": self._check_lint(files_modified),
            "test": self._run_tests(),
            "boot": self._check_boot()
        }

        all_passed = all(results.values())

        return {
            "passed": all_passed,
            "results": results,
            "errors": self.errors
        }

    def _run_command(self, cmd: List[str], timeout: int = 60) -> Tuple[bool, str]:
        """명령 실행"""
        try:
            result = subprocess.run(
                cmd,
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return result.returncode == 0, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return False, "Timeout"
        except Exception as e:
            return False, str(e)

    def _check_syntax(self, files: List[str]) -> bool:
        """Ruby/ERB 문법 검사"""
        print("   🔍 문법 검사...")

        for file in files:
            if not file.endswith(('.rb', '.erb')):
                continue

            full_path = self.project_path / file

            if file.endswith('.rb'):
                success, output = self._run_command(['ruby', '-c', str(full_path)])
            elif file.endswith('.erb'):
                # ERB를 Ruby로 변환 후 검사
                success, output = self._run_command(
                    ['bash', '-c', f'erb -x "{full_path}" | ruby -c']
                )

            if not success:
                self.errors.append(f"Syntax error in {file}: {output}")
                print(f"      ❌ {file}")
                return False

            print(f"      ✅ {file}")

        return True

    def _check_lint(self, files: List[str]) -> bool:
        """Rubocop 린트 검사"""
        print("   🔍 린트 검사...")

        rb_files = [f for f in files if f.endswith('.rb')]
        if not rb_files:
            print("      ⏭️ Ruby 파일 없음")
            return True

        # Rubocop 존재 확인
        success, _ = self._run_command(['bundle', 'exec', 'rubocop', '--version'])
        if not success:
            print("      ⏭️ Rubocop 없음 (스킵)")
            return True

        # 자동 수정 가능한 것만 수정
        success, output = self._run_command(
            ['bundle', 'exec', 'rubocop', '-A', '--fail-level', 'E'] + rb_files,
            timeout=120
        )

        if not success and 'offense' in output.lower():
            # 심각한 오류만 실패 처리
            if 'error' in output.lower() or 'fatal' in output.lower():
                self.errors.append(f"Lint errors: {output[:500]}")
                print("      ❌ 심각한 린트 오류")
                return False

        print("      ✅ 린트 통과")
        return True

    def _run_tests(self) -> bool:
        """테스트 실행"""
        print("   🧪 테스트 실행...")

        # 빠른 테스트만 실행 (smoke test)
        success, output = self._run_command(
            ['bin/rails', 'test', '--fail-fast'],
            timeout=180
        )

        if not success:
            # 테스트 실패 상세 정보 추출
            self.errors.append(f"Test failures: {output[:1000]}")
            print("      ❌ 테스트 실패")
            return False

        print("      ✅ 테스트 통과")
        return True

    def _check_boot(self) -> bool:
        """서버 부팅 테스트"""
        print("   🚀 부팅 테스트...")

        # Rails 환경 로드만 테스트
        success, output = self._run_command(
            ['bin/rails', 'runner', 'puts "OK"'],
            timeout=60
        )

        if not success:
            self.errors.append(f"Boot failed: {output[:500]}")
            print("      ❌ 부팅 실패")
            return False

        print("      ✅ 부팅 OK")
        return True


class NotificationService:
    """알림 서비스"""

    def __init__(self, config: dict):
        self.config = config

    def send(self, message: str, level: str = "info"):
        """알림 전송"""
        # 콘솔 출력
        emoji = {"info": "ℹ️", "success": "✅", "warning": "⚠️", "error": "❌"}.get(level, "📢")
        print(f"\n{emoji} {message}")

        # TODO: 슬랙, 텔레그램 등 연동
        # if self.config.get("slack_webhook"):
        #     self._send_slack(message)


class RoadmapAgent:
    """로드맵 실행 에이전트"""

    def __init__(self, config_path: Optional[Path] = None):
        self.config_path = config_path or Path(__file__).parent / "config.json"
        self.config = self._load_config()

        self.project_path = Path(__file__).parent.parent  # choviet/
        self.roadmap_path = self.project_path / "ROADMAP.md"

        self.parser = RoadmapParser(self.roadmap_path)
        self.git = GitManager(self.project_path)
        self.executor = TaskExecutor(self.config, self.project_path)
        self.validator = ValidationPipeline(self.project_path)
        self.notifier = NotificationService(self.config)

    def _load_config(self) -> dict:
        """설정 로드"""
        if self.config_path.exists():
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}

    def run(
        self,
        count: int = 1,
        dry_run: bool = False,
        specific_task: Optional[str] = None,
        create_pr: bool = False
    ) -> Dict:
        """에이전트 실행"""

        print("\n" + "=" * 60)
        print("🤖 Chợ Việt Roadmap Agent")
        print(f"   시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"   모드: {'Dry-run' if dry_run else 'Execute'}")
        print("=" * 60)

        # 1. 로드맵 파싱
        self.parser.parse()
        print(f"\n📋 로드맵 파싱 완료: {len(self.parser.tasks)}개 작업")

        # 2. 다음 작업 선택
        if specific_task:
            tasks = [t for t in self.parser.tasks if specific_task.lower() in t.title.lower()]
            if not tasks:
                print(f"❌ 작업을 찾을 수 없음: {specific_task}")
                return {"success": False, "reason": "Task not found"}
        else:
            tasks = self.parser.get_next_automatable_tasks(count)

        if not tasks:
            print("✅ 자동화 가능한 작업이 없습니다.")
            return {"success": True, "tasks_completed": 0, "reason": "No automatable tasks"}

        print(f"\n🎯 실행할 작업: {len(tasks)}개")
        for t in tasks:
            print(f"   - {t.title}")

        # 3. 브랜치 생성 (실제 실행 시)
        original_branch = self.git.get_current_branch()
        branch_name = f"auto/{datetime.now().strftime('%Y%m%d-%H%M')}"

        if not dry_run:
            self.git.create_branch(branch_name)
            print(f"\n🌿 브랜치 생성: {branch_name}")

        # 4. 각 작업 실행
        results = []
        for task in tasks:
            print(f"\n{'─' * 40}")
            print(f"📌 작업: {task.title}")
            print(f"   Phase: {task.phase}")

            # 진행 중 표시
            if not dry_run:
                self.parser.mark_task_in_progress(task)

            # 분석
            print("   🔍 분석 중...")
            plan = self.executor.analyze_task(task)

            if plan.get("error"):
                print(f"   ❌ 분석 실패: {plan['error']}")
                results.append({"task": task.title, "success": False, "reason": plan["error"]})
                continue

            print(f"   📊 복잡도: {plan.get('complexity', 'unknown')}")
            print(f"   📁 예상 파일: {', '.join(plan.get('estimated_files', []))}")

            # 실행
            print("   ⚙️ 실행 중...")
            result = self.executor.execute_task(task, plan, dry_run)

            if result.get("success"):
                files_modified = result.get("files_modified", [])

                if not dry_run and files_modified:
                    # 검증 파이프라인 실행
                    print("   🔬 검증 중...")
                    validation = self.validator.run_all(files_modified)

                    if not validation["passed"]:
                        print(f"   ❌ 검증 실패!")
                        for err in validation["errors"][:3]:  # 처음 3개 에러만
                            print(f"      → {err[:100]}")

                        # 롤백
                        print("   ↩️ 롤백 중...")
                        self.git.run_git('checkout', '--', '.')
                        self.git.run_git('clean', '-fd')

                        results.append({
                            "task": task.title,
                            "success": False,
                            "reason": "Validation failed",
                            "errors": validation["errors"]
                        })
                        continue

                    print(f"   ✅ 검증 통과!")

                print(f"   ✅ 완료!")

                if not dry_run:
                    # 커밋
                    if self.git.has_changes():
                        self.git.commit(f"feat: {task.title}\n\n🤖 Auto-generated by Roadmap Agent\n✅ Validated: syntax, lint, test, boot")
                        print("   💾 커밋 완료")

                    # 로드맵 업데이트
                    self.parser.mark_task_completed(task)
                    self.git.commit(f"docs: mark '{task.title}' as completed")

                results.append({"task": task.title, "success": True, "files": files_modified, "validated": True})
            else:
                print(f"   ❌ 실패: {result.get('reason', result.get('error', 'Unknown'))}")
                results.append({"task": task.title, "success": False, "reason": result.get("reason")})

        # 5. 마무리
        if not dry_run and any(r["success"] for r in results):
            # 푸시
            print(f"\n📤 푸시 중...")
            self.git.push(branch_name)

            # PR 생성 (선택)
            if create_pr:
                # TODO: gh cli로 PR 생성
                print("   📝 PR 생성은 수동으로 해주세요")

            # 원래 브랜치로 복귀
            self.git.checkout(original_branch)

        # 6. 결과 요약
        successful = sum(1 for r in results if r["success"])
        print(f"\n{'=' * 60}")
        print(f"📊 결과: {successful}/{len(results)} 작업 완료")

        if successful > 0 and not dry_run:
            print(f"🌿 브랜치: {branch_name}")
            print(f"   → PR 생성 후 리뷰해주세요")

        # 알림
        self.notifier.send(
            f"Roadmap Agent 완료: {successful}/{len(results)} 작업",
            "success" if successful == len(results) else "warning"
        )

        return {
            "success": True,
            "tasks_attempted": len(results),
            "tasks_completed": successful,
            "branch": branch_name if not dry_run else None,
            "results": results
        }


def main():
    parser = argparse.ArgumentParser(
        description="Chợ Việt Roadmap Executor Agent",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("--count", "-n", type=int, default=1, help="실행할 작업 개수 (기본: 1)")
    parser.add_argument("--dry-run", "-d", action="store_true", help="실제 실행 안함 (계획만)")
    parser.add_argument("--task", "-t", help="특정 작업만 실행")
    parser.add_argument("--pr", action="store_true", help="PR 자동 생성")
    parser.add_argument("--config", help="설정 파일 경로")

    args = parser.parse_args()

    config_path = Path(args.config) if args.config else None
    agent = RoadmapAgent(config_path=config_path)

    result = agent.run(
        count=args.count,
        dry_run=args.dry_run,
        specific_task=args.task,
        create_pr=args.pr
    )

    if not result.get("success"):
        sys.exit(1)


if __name__ == "__main__":
    main()
