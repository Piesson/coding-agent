#!/bin/bash
# 범용 검증 스크립트 - 프로젝트 타입 자동 감지 후 검증 실행
# Stop Hook에서 호출됨

PROJECT_DIR=$(pwd)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
PENDING_FIXES="$HOME/.claude/pending-fixes.md"
ERRORS=""
PROJECT_TYPE=""

# 프로젝트 타입 감지 함수
detect_project_type() {
    # Node.js 프로젝트
    if [ -f "package.json" ]; then
        echo "nodejs"
        return
    fi

    # Python 프로젝트 (다양한 경우 감지)
    if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
        echo "python"
        return
    fi
    # tests/ 폴더에 Python 테스트가 있는 경우
    if [ -d "tests" ] && ls tests/*.py 2>/dev/null >&2; then
        echo "python"
        return
    fi
    # agent/, src/, lib/ 등 하위 폴더에 Python 파일이 있는 경우
    if ls agent/*.py src/*.py lib/*.py 2>/dev/null >&2; then
        echo "python"
        return
    fi
    # 루트에 main.py 또는 app.py가 있는 경우
    if [ -f "main.py" ] || [ -f "app.py" ]; then
        echo "python"
        return
    fi

    # Rust 프로젝트
    if [ -f "Cargo.toml" ]; then
        echo "rust"
        return
    fi

    # Go 프로젝트
    if [ -f "go.mod" ]; then
        echo "go"
        return
    fi

    # Makefile 프로젝트
    if [ -f "Makefile" ]; then
        echo "make"
        return
    fi

    # Shell 스크립트 프로젝트 (마지막으로 확인)
    if ls *.sh 2>/dev/null >&2 || ls scripts/*.sh 2>/dev/null >&2; then
        echo "shell"
        return
    fi

    echo "unknown"
}

# Node.js 검증
verify_nodejs() {
    local exit_code=0
    local output=""

    # TypeScript 타입 체크
    if [ -f "tsconfig.json" ] && command -v npx &> /dev/null; then
        echo "  → TypeScript type check..."
        output=$(npx tsc --noEmit 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="TypeScript check failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    # 빌드 검증
    if grep -q '"build"' package.json 2>/dev/null; then
        echo "  → Running build..."
        output=$(npm run build 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Build failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    # 린트 검증
    if grep -q '"lint"' package.json 2>/dev/null; then
        echo "  → Running lint..."
        output=$(npm run lint 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Lint failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    # 테스트 검증
    if grep -q '"test"' package.json 2>/dev/null; then
        echo "  → Running tests..."
        output=$(npm test 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Test failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    # Playwright E2E (웹 앱인 경우)
    if ls test/*.spec.ts tests/*.spec.ts e2e/*.spec.ts 2>/dev/null >&2; then
        echo "  → Running Playwright E2E tests..."
        output=$(npx playwright test --reporter=list 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="E2E tests failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    return $exit_code
}

# Python 검증
verify_python() {
    local exit_code=0
    local output=""

    # mypy 타입 체크
    if [ -f "mypy.ini" ] || grep -q "mypy" pyproject.toml 2>/dev/null; then
        echo "  → Running mypy type check..."
        output=$(python3 -m mypy . 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Mypy check failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    # pytest 실행
    if command -v pytest &> /dev/null; then
        echo "  → Running pytest..."
        output=$(pytest -v 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Pytest failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    # 메인 스크립트 실행 테스트 (--help 또는 --version)
    if [ -f "main.py" ]; then
        echo "  → Checking main.py execution..."
        output=$(python3 main.py --help 2>&1 || python3 -c "import main" 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Main script check failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    return $exit_code
}

# Rust 검증
verify_rust() {
    local exit_code=0
    local output=""

    echo "  → Running cargo check..."
    output=$(cargo check 2>&1)
    if [ $? -ne 0 ]; then
        ERRORS+="Cargo check failed:\n$output\n\n"
        exit_code=1
    fi

    echo "  → Running cargo test..."
    output=$(cargo test 2>&1)
    if [ $? -ne 0 ]; then
        ERRORS+="Cargo test failed:\n$output\n\n"
        exit_code=1
    fi

    return $exit_code
}

# Go 검증
verify_go() {
    local exit_code=0
    local output=""

    echo "  → Running go build..."
    output=$(go build ./... 2>&1)
    if [ $? -ne 0 ]; then
        ERRORS+="Go build failed:\n$output\n\n"
        exit_code=1
    fi

    echo "  → Running go test..."
    output=$(go test ./... 2>&1)
    if [ $? -ne 0 ]; then
        ERRORS+="Go test failed:\n$output\n\n"
        exit_code=1
    fi

    return $exit_code
}

# Makefile 검증
verify_make() {
    local exit_code=0
    local output=""

    # test 타겟이 있으면 실행
    if grep -q "^test:" Makefile 2>/dev/null; then
        echo "  → Running make test..."
        output=$(make test 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Make test failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    # build 타겟이 있으면 실행
    if grep -q "^build:" Makefile 2>/dev/null; then
        echo "  → Running make build..."
        output=$(make build 2>&1)
        if [ $? -ne 0 ]; then
            ERRORS+="Make build failed:\n$output\n\n"
            exit_code=1
        fi
    fi

    return $exit_code
}

# Shell 스크립트 검증
verify_shell() {
    local exit_code=0
    local output=""

    # shellcheck 실행 (설치된 경우)
    if command -v shellcheck &> /dev/null; then
        echo "  → Running shellcheck..."
        for script in *.sh scripts/*.sh; do
            if [ -f "$script" ]; then
                output=$(shellcheck "$script" 2>&1)
                if [ $? -ne 0 ]; then
                    ERRORS+="Shellcheck failed for $script:\n$output\n\n"
                    exit_code=1
                fi
            fi
        done
    fi

    # 문법 검사 (bash -n)
    echo "  → Checking shell syntax..."
    for script in *.sh scripts/*.sh; do
        if [ -f "$script" ]; then
            output=$(bash -n "$script" 2>&1)
            if [ $? -ne 0 ]; then
                ERRORS+="Syntax error in $script:\n$output\n\n"
                exit_code=1
            fi
        fi
    done

    return $exit_code
}

# 검증 실행 함수
run_verification() {
    local type=$1

    case $type in
        nodejs)
            verify_nodejs
            ;;
        python)
            verify_python
            ;;
        rust)
            verify_rust
            ;;
        go)
            verify_go
            ;;
        make)
            verify_make
            ;;
        shell)
            verify_shell
            ;;
        *)
            echo "No verification method for type: $type"
            return 0
            ;;
    esac

    return $?
}

# 오류 기록 함수
log_errors() {
    if [ -n "$ERRORS" ]; then
        # 파일 크기가 1MB 초과 시 자동 초기화 (무한 증가 방지)
        if [ -f "$PENDING_FIXES" ] && [ $(wc -c < "$PENDING_FIXES") -gt 1048576 ]; then
            echo "# Pending Fixes" > "$PENDING_FIXES"
            echo "" >> "$PENDING_FIXES"
            echo "이 파일의 오류들을 확인하고 수정해주세요." >> "$PENDING_FIXES"
            echo "" >> "$PENDING_FIXES"
            echo "⚠️  pending-fixes.md가 1MB 초과하여 자동 초기화했습니다."
        fi

        # pending-fixes.md 파일이 없으면 헤더 생성
        if [ ! -f "$PENDING_FIXES" ]; then
            echo "# Pending Fixes" > "$PENDING_FIXES"
            echo "" >> "$PENDING_FIXES"
            echo "이 파일의 오류들을 확인하고 수정해주세요." >> "$PENDING_FIXES"
            echo "" >> "$PENDING_FIXES"
        fi

        # 오류 내용 추가
        {
            echo ""
            echo "## [$TIMESTAMP] $PROJECT_DIR"
            echo ""
            echo "### 검증 실패"
            echo "- **타입**: $PROJECT_TYPE"
            echo ""
            echo "### 오류 내용"
            echo '```'
            echo -e "$ERRORS"
            echo '```'
            echo ""
            echo "---"
        } >> "$PENDING_FIXES"

        echo ""
        echo "⚠️  오류가 ~/.claude/pending-fixes.md에 기록되었습니다."
        echo "    다음 Claude 세션에서 자동으로 수정을 시도합니다."
    fi
}

# 메인 실행
echo "========================================"
echo "🔍 Universal Verification System"
echo "========================================"
echo "📁 Project: $PROJECT_DIR"
echo ""

PROJECT_TYPE=$(detect_project_type)
echo "📋 Detected type: $PROJECT_TYPE"
echo ""

if [ "$PROJECT_TYPE" = "unknown" ]; then
    echo "ℹ️  No verification method detected for this project."
    echo "    Skipping verification."
    exit 0
fi

echo "🚀 Running verification..."
echo ""

run_verification "$PROJECT_TYPE"
FINAL_EXIT=$?

echo ""
echo "========================================"

if [ $FINAL_EXIT -ne 0 ]; then
    echo "❌ Verification FAILED"
    log_errors
else
    echo "✅ Verification PASSED"

    # 성공 시 이 프로젝트의 이전 오류 기록 삭제 (있다면)
    if [ -f "$PENDING_FIXES" ]; then
        # 해당 프로젝트 섹션만 삭제 (복잡한 로직은 생략, 수동으로 관리)
        :
    fi
fi

echo "========================================"
exit $FINAL_EXIT
