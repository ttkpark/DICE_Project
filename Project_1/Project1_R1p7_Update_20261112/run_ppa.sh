#!/usr/bin/env bash
set -euo pipefail
# 패키지 루트에서 동일 RTL·주기·프로그램의 CPU 합성·전력 측정
cd -- "$(dirname -- "$0")"
if [[ ! -x /usr/bin/python3.12 ]]; then
    echo "Project 1: Python 3.12 was not found at /usr/bin/python3.12 on DICE." >&2
    exit 1
fi
synopsys_bin=/opt/eda/synopsys/products/syn/V-2023.12-SP5/bin
if [[ ! -x "$synopsys_bin/vcd2saif" ]]; then
    echo "Project 1: vcd2saif was not found at $synopsys_bin/vcd2saif on DICE." >&2
    exit 1
fi
export PATH="$synopsys_bin:$PATH"
exec /usr/bin/python3.12 tools/run_flow.py ppa
