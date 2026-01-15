# Coding Agent

Claude Code를 위한 범용 코딩 에이전트 환경.

## Features

- `/create-agent` 명령으로 새 에이전트 프로젝트 스캐폴딩
- PostToolUse Hook으로 CLAUDE.md/README.md 자동 업데이트
- Stop Hook으로 Playwright 테스트 자동 실행
- Platonic Clarification Protocol (질문-우선 프로토콜) 내장

## Quick Start

```bash
cd ~/Desktop/coding-agent
claude
```

## Usage

### 새 에이전트 생성

```bash
> /create-agent slack-bot
# ~/Desktop/slack-bot/ 폴더가 생성됨
```

생성되는 구조:
```
slack-bot/
├── CLAUDE.md          # 프로젝트 컨텍스트
├── README.md          # 프로젝트 설명
└── .claude/
    └── settings.json  # 프로젝트 설정
```

## Project Structure

```
coding-agent/
├── templates/         # 에이전트 템플릿
├── scripts/           # 자동화 스크립트
└── .claude/           # Claude Code 설정
    ├── commands/      # 슬래시 명령어
    └── skills/        # 스킬 정의
```

## Automation

### PostToolUse Hook
- Write/Edit 시 자동 실행
- CLAUDE.md Change Log 업데이트
- README.md 기능 문서화
- Git commit + push

### Stop Hook - 범용 피드백 루프
- Claude 작업 완료 시 `run-verification.sh` 실행
- 프로젝트 타입 자동 감지 (Node.js, Python, Rust, Go, Make, Shell)
- 타입별 검증 실행 (빌드, 테스트, 린트, 타입체크)
- 실패 시 `~/.claude/pending-fixes.md`에 오류 기록
- 다음 세션에서 Claude가 자동 수정 시도

### 지원하는 프로젝트 타입

| 타입 | 감지 파일 | 검증 명령 |
|------|----------|----------|
| Node.js | package.json | npm build/test/lint |
| Python | pytest.ini, pyproject.toml | pytest, mypy |
| Rust | Cargo.toml | cargo check/test |
| Go | go.mod | go build/test |
| Make | Makefile | make build/test |
| Shell | *.sh | shellcheck, bash -n |

## Changelog

### 2026-01-15
- Initial setup
- Phase 2: 범용 피드백 루프 시스템 추가
