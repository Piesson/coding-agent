#!/bin/bash
# Stop Hook: Playwright 테스트 실행
# Claude 작업 완료 시 자동 실행

PROJECT_DIR=$(pwd)

# 웹 프로젝트인지 확인 (package.json 또는 index.html 존재)
is_web_project() {
    [ -f "$PROJECT_DIR/package.json" ] || \
    [ -f "$PROJECT_DIR/index.html" ] || \
    [ -d "$PROJECT_DIR/src" ] || \
    [ -d "$PROJECT_DIR/public" ]
}

# Playwright 테스트 파일 존재 확인
has_playwright_tests() {
    ls "$PROJECT_DIR"/test/*.spec.ts 2>/dev/null || \
    ls "$PROJECT_DIR"/test/*.test.ts 2>/dev/null || \
    ls "$PROJECT_DIR"/tests/*.spec.ts 2>/dev/null || \
    ls "$PROJECT_DIR"/tests/*.test.ts 2>/dev/null || \
    ls "$PROJECT_DIR"/e2e/*.spec.ts 2>/dev/null || \
    ls "$PROJECT_DIR"/e2e/*.test.ts 2>/dev/null
}

# 웹 프로젝트가 아니면 스킵
if ! is_web_project; then
    exit 0
fi

# Playwright 테스트 파일이 있으면 실행
if has_playwright_tests; then
    echo "=== Running Playwright Tests ==="

    # package.json에 playwright 스크립트가 있는지 확인
    if [ -f "$PROJECT_DIR/package.json" ] && grep -q '"test:e2e"' "$PROJECT_DIR/package.json"; then
        npm run test:e2e
    elif [ -f "$PROJECT_DIR/package.json" ] && grep -q '"playwright"' "$PROJECT_DIR/package.json"; then
        npx playwright test
    else
        # 기본 playwright 실행
        npx playwright test --reporter=list
    fi

    TEST_EXIT_CODE=$?

    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo "=== Playwright Tests Passed ==="
    else
        echo "=== Playwright Tests Failed (Exit code: $TEST_EXIT_CODE) ==="
    fi

    exit $TEST_EXIT_CODE
else
    # 테스트 파일이 없으면 Playwright MCP로 수동 확인 안내
    echo "No Playwright test files found."
    echo "Use Playwright MCP for manual browser verification if needed."
    exit 0
fi
