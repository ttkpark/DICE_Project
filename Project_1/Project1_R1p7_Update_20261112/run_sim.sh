#!/usr/bin/env bash
set -euo pipefail
# 패키지 루트로 이동한 다음 공통 VCS 기능·activity 실행
cd -- "$(dirname -- "$0")"
if [[ ! -x /usr/bin/python3.12 ]]; then
    echo "Project 1: Python 3.12 was not found at /usr/bin/python3.12 on DICE." >&2
    exit 1
fi
exec /usr/bin/python3.12 tools/run_flow.py sim "$@"
