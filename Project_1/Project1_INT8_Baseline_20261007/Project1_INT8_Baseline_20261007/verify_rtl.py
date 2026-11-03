#!/usr/bin/env python3
"""Icarus 또는 VCS에서 독립 behavioral HDL 실행 모델 전체 회귀."""
import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--backend", choices=["iverilog", "vcs"], default="iverilog")
parser.add_argument("--compiler", help="선택: iverilog 또는 vcs 절대 경로")
parser.add_argument("--vvp", help="선택: vvp 절대 경로")
args = parser.parse_args()
build = ROOT / "build"
logs = ROOT / "logs"
build.mkdir(exist_ok=True)
logs.mkdir(exist_ok=True)
exe = build / ("behavior.vvp" if args.backend == "iverilog" else "simv")
compiler = args.compiler or shutil.which(args.backend)
if not compiler:
    raise SystemExit(f"{args.backend} 없음. 먼저 설치/서버 환경 확인 필요")
if args.backend == "iverilog":
    cmd = [compiler, "-g2012", "-s", "TB_BEHAVIOR_CPU", "-o", str(exe), "sim/tb_behavior_cpu.sv"]
else:
    cmd = [compiler, "-full64", "-sverilog", "-top", "TB_BEHAVIOR_CPU", "-o", str(exe), "sim/tb_behavior_cpu.sv"]
compiled = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=120)
(logs / "compile.log").write_text(compiled.stdout + compiled.stderr, encoding="utf-8")
if compiled.returncode:
    raise SystemExit("컴파일 실패. logs/compile.log 확인")
runner = args.vvp or shutil.which("vvp") if args.backend == "iverilog" else None
if args.backend == "iverilog" and not runner:
    raise SystemExit("vvp 없음")
word_count = len((ROOT / "baseline_int8_fc_slow.hex").read_text(encoding="ascii").splitlines())
functional = json.loads((ROOT / "FUNCTIONAL_VALIDATION.json").read_text(encoding="utf-8"))
previous = {c["case"]: c for c in functional["cases"]}
results = []
for case_path in sorted((ROOT / "cases").glob("*.json")):
    case = json.loads(case_path.read_text(encoding="utf-8"))
    cmd = ([runner, str(exe)] if runner else [str(exe)]) + [
        "+PROGRAM=baseline_int8_fc_slow.hex", f"+DATA=cases/{case['memory_file']}",
        f"+EXPECTED=cases/{case['expected_file']}", f"+WORDS={word_count}"]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=60)
    log = result.stdout + result.stderr
    (logs / f"{case['name']}.log").write_text(log, encoding="utf-8")
    match = re.search(r"PASS RTL_MODEL steps=(\d+) loads=(\d+) stores=(\d+) Y=([-0-9,]+)", log)
    if result.returncode or not match:
        raise SystemExit(f"FAIL {case['name']}: logs/{case['name']}.log 확인")
    steps, loads, stores = map(int, match.group(1,2,3))
    outputs = list(map(int, match[4].split(",")))
    ref = previous[case["name"]]
    if (steps, loads, stores, outputs) != (ref["instructions"], ref["data_loads"], ref["data_stores"], case["expected_outputs"]):
        raise SystemExit("Python/HDL 실행 결과 또는 카운트 불일치")
    results.append({"case": case["name"], "instructions": steps, "outputs": outputs, "pass": True})
    print(f"PASS HDL {case['name']}: {steps} instructions")
summary = {"backend": args.backend, "scope": "simulation-only behavioral model, not gate-level timing or PPA",
           "passed": len(results), "case_count": len(results), "cases": results}
(ROOT / "HDL_VALIDATION.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"TOTAL HDL PASS {len(results)}/{len(results)}")
