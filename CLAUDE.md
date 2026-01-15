# Coding Agent

Claude Code를 위한 범용 코딩 에이전트 환경. 새 에이전트(자동화, CLI, Slack 봇)를 빠르게 생성하고, 코드 변경 시 자동으로 문서화/테스트/커밋이 이루어지는 시스템.

---

## Core Identity

- **목적**: 새 에이전트 프로젝트 스캐폴딩 및 자동화
- **핵심 기능**: `/create-agent` 명령으로 에이전트 템플릿 생성
- **자동화**: 코드 변경 시 문서 업데이트, Playwright 테스트

---

## Platonic Clarification Protocol

모든 작업 전 필수 평가:
1. **명시적 작성**: "질문 필요 여부: YES/NO"
2. YES인 경우 1-3개 질문 후 진행
3. 범위/깊이/컨텍스트 확인
4. 답변 받은 후에만 본격 진행

---

## Commands

| 명령어 | 설명 |
|--------|------|
| `/create-agent <name>` | 새 에이전트 프로젝트 스캐폴딩 |

---

## Project Structure

```
coding-agent/
├── CLAUDE.md                    # 이 파일
├── README.md                    # 프로젝트 설명
├── .claude/
│   ├── settings.json            # 프로젝트 설정
│   ├── commands/
│   │   └── create-agent.md      # /create-agent 명령어
│   └── skills/
│       └── platonic-clarification/
│           └── SKILL.md         # 질문-우선 프로토콜
├── templates/                   # 에이전트 템플릿
│   ├── CLAUDE.md.template
│   ├── README.md.template
│   └── settings.json.template
└── scripts/                     # 자동화 스크립트
    ├── auto-update-docs.sh
    └── run-playwright.sh
```

---

## Change Log

### 2026-01-15
- Initial setup: coding-agent 프로젝트 생성
- Phase 2: 범용 피드백 루프 시스템 추가
  - `run-verification.sh`: 프로젝트 타입 자동 감지 및 검증
  - `~/.claude/pending-fixes.md`: 실패 시 오류 로깅 → 다음 세션에서 자동 수정
