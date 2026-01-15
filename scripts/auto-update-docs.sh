#!/bin/bash
# PostToolUse Hook: 코드 변경 시 자동 문서 업데이트 + Git
# Write|Edit 도구 사용 후 자동 실행

PROJECT_DIR=$(pwd)
DATE=$(date +%Y-%m-%d)

# stdin에서 tool_input 받기 (JSON 형식)
INPUT=$(cat)

# 변경된 파일 경로 추출 (있는 경우)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

# 파일 경로가 없거나 .md 파일이면 스킵 (무한 루프 방지)
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# .md 파일 수정은 스킵 (CLAUDE.md, README.md 업데이트 시 재귀 방지)
if [[ "$FILE_PATH" == *.md ]]; then
    exit 0
fi

# 설정 파일 수정도 스킵
if [[ "$FILE_PATH" == *.json ]] || [[ "$FILE_PATH" == *.yaml ]] || [[ "$FILE_PATH" == *.yml ]]; then
    exit 0
fi

# 스크립트 파일 수정도 스킵
if [[ "$FILE_PATH" == *.sh ]]; then
    exit 0
fi

# 프로젝트 루트 찾기 (git repo 루트 또는 CLAUDE.md가 있는 곳)
find_project_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/CLAUDE.md" ] || [ -d "$dir/.git" ]; then
            echo "$dir"
            return
        fi
        dir=$(dirname "$dir")
    done
    echo ""
}

FILE_DIR=$(dirname "$FILE_PATH")
PROJECT_ROOT=$(find_project_root "$FILE_DIR")

# 프로젝트 루트를 찾지 못하면 스킵
if [ -z "$PROJECT_ROOT" ]; then
    exit 0
fi

cd "$PROJECT_ROOT"

# 파일명만 추출
FILENAME=$(basename "$FILE_PATH")

# CLAUDE.md Change Log 업데이트
if [ -f "CLAUDE.md" ]; then
    # Change Log 섹션이 있는지 확인
    if grep -q "## Change Log" CLAUDE.md; then
        # 오늘 날짜 항목이 이미 있는지 확인
        if ! grep -q "### $DATE" CLAUDE.md; then
            # 새 날짜 섹션 추가
            sed -i '' "/## Change Log/a\\
### $DATE\\
" CLAUDE.md 2>/dev/null || true
        fi

        # 파일 변경 항목 추가 (중복 방지)
        if ! grep -q "- \[$FILENAME\]" CLAUDE.md; then
            sed -i '' "/### $DATE/a\\
- [$FILENAME]: Updated\\
" CLAUDE.md 2>/dev/null || true
        fi
    fi
fi

# Git 상태 확인 및 자동 커밋 (git repo인 경우에만)
if [ -d ".git" ]; then
    # 변경사항이 있는지 확인
    if ! git diff --quiet HEAD 2>/dev/null; then
        # 자동 커밋은 비활성화 (사용자가 명시적으로 요청할 때만)
        # git add -A
        # git commit -m "Auto-update: $FILENAME ($DATE)"
        # git push
        :
    fi
fi

# 성공적으로 완료
exit 0
