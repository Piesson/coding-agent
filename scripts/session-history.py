#!/usr/bin/env python3
"""
Claude Code Session History Analyzer
오늘 (KST 기준) Claude Code로 작업한 내역을 요약해주는 스크립트
"""

import json
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from collections import defaultdict
import argparse


def get_kst_today_range():
    """KST 기준 오늘의 UTC 시간 범위 반환"""
    # 현재 UTC 시간
    utc_now = datetime.now(timezone.utc)
    # KST = UTC + 9
    kst_now = utc_now + timedelta(hours=9)

    # KST 기준 오늘 00:00:00
    kst_today_start = kst_now.replace(hour=0, minute=0, second=0, microsecond=0)
    # UTC로 변환 (KST - 9시간)
    utc_start = kst_today_start - timedelta(hours=9)
    utc_end = utc_start + timedelta(days=1)

    return utc_start, utc_end


def get_kst_date_range(date_str):
    """특정 날짜 (YYYY-MM-DD)의 KST 기준 UTC 시간 범위 반환"""
    kst_date = datetime.strptime(date_str, "%Y-%m-%d")
    utc_start = kst_date - timedelta(hours=9)
    utc_end = utc_start + timedelta(days=1)
    return utc_start, utc_end


def find_session_files(projects_dir, utc_start, utc_end):
    """주어진 시간 범위 내의 세션 파일들 찾기"""
    session_files = []

    for project_dir in projects_dir.iterdir():
        if not project_dir.is_dir():
            continue
        if project_dir.name.startswith('.'):
            continue

        for jsonl_file in project_dir.glob("*.jsonl"):
            # 파일 수정 시간 확인
            mtime = datetime.fromtimestamp(jsonl_file.stat().st_mtime, tz=timezone.utc)

            # 시간 범위 내 파일만 포함
            if utc_start <= mtime <= utc_end:
                session_files.append(jsonl_file)

    return sorted(session_files, key=lambda f: f.stat().st_mtime)


def parse_session(jsonl_path):
    """세션 파일에서 정보 추출"""
    sessions = []

    with open(jsonl_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)

                # 사용자 메시지 찾기
                if data.get("type") == "user" and data.get("message", {}).get("role") == "user":
                    timestamp = data.get("timestamp", "")
                    content = data.get("message", {}).get("content", "")

                    if isinstance(content, str):
                        # 시스템 메시지 제외
                        if content.startswith("<local-command"):
                            content = "[로컬 명령어 실행]"
                        elif content.startswith("<command-message>"):
                            # 슬래시 커맨드 추출
                            import re
                            match = re.search(r'<command-name>(/[^<]+)</command-name>', content)
                            if match:
                                content = f"[슬래시 커맨드: {match.group(1)}]"

                        msg = content[:200].replace("\n", " ").strip()
                    else:
                        msg = "[복합 메시지]"

                    sessions.append({
                        "timestamp": timestamp,
                        "message": msg
                    })
                    break  # 첫 번째 사용자 메시지만

            except json.JSONDecodeError:
                continue

    return sessions


def extract_project_name(path):
    """경로에서 프로젝트명 추출"""
    name = path.parent.name
    # -Users-apple-Desktop-projectname 형식에서 프로젝트명만 추출
    if name.startswith("-Users-apple-Desktop-"):
        return name.replace("-Users-apple-Desktop-", "")
    elif name.startswith("-Users-apple-"):
        return name.replace("-Users-apple-", "")
    return name


def format_timestamp_kst(utc_timestamp):
    """UTC 타임스탬프를 KST로 변환"""
    if not utc_timestamp:
        return "시간 불명"

    try:
        # ISO 형식 파싱
        utc_dt = datetime.fromisoformat(utc_timestamp.replace('Z', '+00:00'))
        kst_dt = utc_dt + timedelta(hours=9)
        return kst_dt.strftime("%H:%M")
    except:
        return utc_timestamp[:16]


def main():
    parser = argparse.ArgumentParser(description='Claude Code 세션 히스토리 분석')
    parser.add_argument('--date', '-d', help='분석할 날짜 (YYYY-MM-DD, 기본: 오늘)')
    parser.add_argument('--verbose', '-v', action='store_true', help='상세 출력')
    args = parser.parse_args()

    # Claude 프로젝트 디렉토리
    projects_dir = Path.home() / ".claude" / "projects"

    if not projects_dir.exists():
        print("❌ Claude Code 프로젝트 디렉토리를 찾을 수 없습니다.")
        return

    # 시간 범위 설정
    if args.date:
        utc_start, utc_end = get_kst_date_range(args.date)
        date_str = args.date
    else:
        utc_start, utc_end = get_kst_today_range()
        kst_now = datetime.now(timezone.utc) + timedelta(hours=9)
        date_str = kst_now.strftime("%Y-%m-%d")

    # 세션 파일 찾기
    session_files = find_session_files(projects_dir, utc_start, utc_end)

    if not session_files:
        print(f"📭 {date_str} (KST) 기준 작업 내역이 없습니다.")
        return

    # 프로젝트별로 그룹화
    by_project = defaultdict(list)

    for sf in session_files:
        project = extract_project_name(sf)
        sessions = parse_session(sf)

        for s in sessions:
            by_project[project].append({
                "time": format_timestamp_kst(s["timestamp"]),
                "message": s["message"]
            })

    # 출력
    print(f"\n📅 {date_str} (KST) Claude Code 작업 내역")
    print("=" * 50)

    total_sessions = 0

    for project, sessions in sorted(by_project.items()):
        print(f"\n📁 {project}")
        print("-" * 40)

        for s in sessions:
            total_sessions += 1
            msg = s["message"]
            if len(msg) > 80:
                msg = msg[:77] + "..."
            print(f"  [{s['time']}] {msg}")

    print(f"\n{'=' * 50}")
    print(f"총 {len(by_project)}개 프로젝트, {total_sessions}개 세션")


if __name__ == "__main__":
    main()
