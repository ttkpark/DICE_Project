#!/usr/bin/env bash
set -euo pipefail
# 패키지 루트로 이동한 다음 공통 VCS 기능·activity 실행
cd -- "$(dirname -- "$0")"
python3 tools/run_flow.py sim
