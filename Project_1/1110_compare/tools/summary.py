#!/usr/bin/env python3
"""세 실험 폴더의 결과를 한 표로 모은다.  python3 tools/summary.py   (run_all.sh 가 마지막에 부른다)

읽는 것 : <실험>/results/sweep.csv                     주기 탐색 (timing 만)
          <실험>/comparisons/<프로그램>_P<주기>/ppa_summary.json   공식 run_sim.sh + run_ppa.sh 결과
쓰는 것 : results/summary.md, results/summary.csv

소수 자리는 열마다 고정한다: 주기 2, 주파수 2, cycle 4 (16 case 평균은 1/16 단위라 4자리면 정확),
T 4, slack 4, 면적 2, 전력 4.  Python 3.6 에서 돈다.
"""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPERIMENTS = ["1110_single_cycle", "1110_pipeline_ID", "1110_pipeline_EX"]

# (열 제목, ppa_summary.json 키, 서식)
COLUMNS = [
    ("period_ns", "period_ns", "{:.2f}"),
    ("f_MHz", "frequency_mhz", "{:.2f}"),
    ("mean_cycles", "mean_cycles", "{:.4f}"),
    ("T_us", "time_us", "{:.4f}"),
    ("setup_slack_ns", "setup_slack_ns", "{:.4f}"),
    ("hold_slack_ns", "hold_slack_ns", "{:.4f}"),
    ("A_cpu_um2", "cpu_cell_area_um2", "{:.2f}"),
    ("A_total_um2", "total_area_um2", "{:.2f}"),
    ("P_cpu_mW", "cpu_power_mw", "{:.4f}"),
    ("P_mem_dyn_mW", "memory_dynamic_mw", "{:.4f}"),
    ("P_mem_static_mW", "memory_static_proxy_mw", "{:.4f}"),
    ("P_total_mW", "total_power_mw", "{:.4f}"),
]


def table(header, rows):
    out = ["| " + " | ".join(header) + " |", "|" + "|".join("---" if i < 2 else "---:" for i in range(len(header))) + "|"]
    return out + ["| " + " | ".join(r) + " |" for r in rows]


(ROOT / "results").mkdir(exist_ok=True)
rows = []
for exp in EXPERIMENTS:
    for f in sorted((ROOT / exp / "comparisons").glob("*/ppa_summary.json")):
        d = json.loads(f.read_text(encoding="utf-8"))
        program = f.parent.name.rsplit("_P", 1)[0]
        rows.append((exp, program, d))

lines = ["# 1110 비교 결과", "",
         "R1.4 공통 flow (run_sim.sh -> run_ppa.sh) 의 공개 16 case 결과. 공식 24 case 성적이 아니다.", ""]
if rows:
    # 이 표 안에서만의 상대 점수: 항목별 최솟값을 best 로 둔 12.5 T + 6.25 A + 6.25 P. 다른 팀 값이 없으므로 실제 점수가 아니다.
    best = {k: min(d[k] for _, _, d in rows) for k in ("time_us", "total_area_um2", "total_power_mw")}
    header = ["experiment", "program"] + [c[0] for c in COLUMNS] + ["score_in_table"]
    body = []
    for exp, program, d in rows:
        score = (12.5 * best["time_us"] / d["time_us"] + 6.25 * best["total_area_um2"] / d["total_area_um2"]
                 + 6.25 * best["total_power_mw"] / d["total_power_mw"])
        body.append([exp, program] + [fmt.format(d[key]) for _, key, fmt in COLUMNS] + ["{:.2f}".format(score)])
    lines += ["## PPA", ""] + table(header, body) + [
        "", "`score_in_table` = 이 표의 행끼리만 비교한 `12.5·T_best/T + 6.25·A_best/A + 6.25·P_best/P`. 실제 점수가 아니다.", ""]
    with (ROOT / "results").joinpath("summary.csv").open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows([header] + body)
else:
    lines += ["PPA 결과 없음 (comparisons/*/ppa_summary.json 이 아직 없다).", ""]

for exp in EXPERIMENTS:
    sweep = ROOT / exp / "results" / "sweep.csv"
    if sweep.is_file():
        data = list(csv.reader(sweep.open(encoding="utf-8")))
        lines += ["## 주기 탐색: " + exp, ""] + table(data[0], data[1:]) + [""]

(ROOT / "results" / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
