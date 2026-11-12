#!/usr/bin/env bash
set -euo pipefail
# 패키지 루트에서 동일 RTL·주기·프로그램의 CPU 합성·전력 측정
cd -- "$(dirname -- "$0")"
python3 tools/run_flow.py ppa
