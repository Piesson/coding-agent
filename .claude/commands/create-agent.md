---
description: 새 에이전트 프로젝트 스캐폴딩. 에이전트 이름을 인자로 받아 ~/Desktop/에 프로젝트 생성.
---

# Create Agent

새 에이전트 프로젝트를 생성합니다.

## 입력
- **프로젝트 이름**: $ARGUMENTS (예: slack-bot, email-notifier)
- **생성 경로**: ~/Desktop/$ARGUMENTS/

## 실행 단계

### 1. 프로젝트 폴더 생성
```bash
mkdir -p ~/Desktop/$ARGUMENTS/.claude
```

### 2. 템플릿 복사 및 변수 치환

**CLAUDE.md 생성:**
- 템플릿: ~/Desktop/coding-agent/templates/CLAUDE.md.template
- 변수 치환:
  - `{{PROJECT_NAME}}` → $ARGUMENTS
  - `{{DATE}}` → 오늘 날짜 (YYYY-MM-DD)

**README.md 생성:**
- 템플릿: ~/Desktop/coding-agent/templates/README.md.template
- 변수 치환:
  - `{{PROJECT_NAME}}` → $ARGUMENTS
  - `{{DATE}}` → 오늘 날짜 (YYYY-MM-DD)

**settings.json 생성:**
- 템플릿: ~/Desktop/coding-agent/templates/settings.json.template
- 경로: ~/Desktop/$ARGUMENTS/.claude/settings.json

### 3. Git 초기화
```bash
cd ~/Desktop/$ARGUMENTS
git init
git add -A
git commit -m "Initial commit: $ARGUMENTS setup"
```

### 4. 완료 메시지
생성된 프로젝트 구조를 출력:
```
✓ 프로젝트 생성 완료: ~/Desktop/$ARGUMENTS/

구조:
$ARGUMENTS/
├── CLAUDE.md
├── README.md
└── .claude/
    └── settings.json

다음 단계:
1. cd ~/Desktop/$ARGUMENTS
2. claude
3. 프로젝트 목적과 기능 정의
```

## 주의사항
- 이미 존재하는 폴더면 경고 후 덮어쓸지 확인
- 프로젝트 이름에 공백이나 특수문자가 있으면 거부
- Git 초기화 실패해도 프로젝트 생성은 완료
