#!/bin/bash
# PreToolUse Hook: 세션 시작 시 pending-fixes.md 확인
# 세션당 한 번만 실행 (플래그 파일 사용)

PENDING_FIXES="$HOME/.claude/pending-fixes.md"
FLAG_DIR="/tmp/claude-pending-flags"
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
FLAG_FILE="$FLAG_DIR/checked-$SESSION_ID"

# 플래그 디렉토리 생성
mkdir -p "$FLAG_DIR" 2>/dev/null

# 이미 이 세션에서 체크했으면 스킵
if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

# 플래그 설정 (이 세션에서 체크했음을 표시)
touch "$FLAG_FILE"

# 오래된 플래그 파일 정리 (24시간 이상)
find "$FLAG_DIR" -name "checked-*" -mtime +1 -delete 2>/dev/null

# pending-fixes.md 파일이 존재하고 내용이 있으면 출력
if [ -f "$PENDING_FIXES" ] && [ -s "$PENDING_FIXES" ]; then
    echo ""
    echo "========================================"
    echo "  PENDING FIXES DETECTED"
    echo "========================================"
    echo ""
    cat "$PENDING_FIXES"
    echo ""
    echo "========================================"
    echo "  위 오류들을 먼저 확인하고 수정해주세요."
    echo "========================================"
    echo ""
fi

exit 0
