#!/usr/bin/env python3
"""build/sim_<program>_<case>.log (VCS 또는 ModelSim) 를 모아 results/cycles.csv 와 요약표를 만든다.
    python3 tools/summarize.py [F_MHZ]
메모리 전력은 PROJECT_CONTRACT_KO.md 산식(모든 case 합산 r_D)으로 다시 계산한다. CPU 전력은 포함하지 않는다."""
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

root = Path(__file__).resolve().parents[1]
f_mhz = float(sys.argv[1]) if len(sys.argv) > 1 else 100.0
IMEM = [(64, 8713.50, 2.23), (256, 27352.30, 7.00), (512, 50667.68, 12.97)]
DMEM_AREA, E_DMEM = 50667.68, 12.97

rows = []
for log in sorted((root / "build").glob("sim_*.log")):
    text = log.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"MEMORY_PPA cycles=(\d+) LOAD=(\d+) STORE=(\d+) IMEM_words=(\d+)", text)
    fail = re.search(r"^.*FAIL.*$", text, re.M)
    name = log.stem[4:]
    prog = next((p for p in ("baseline_int8_fc_slow", "int8_small", "int8_fast") if name.startswith(p + "_")), None)
    if prog is None:
        prog, case = name.rsplit("_", 1)
    else:
        case = name[len(prog) + 1:]
    result = "PASS" if ("PASS TB_TOP_DEMO" in text and not fail) else "FAIL"
    rows.append({"program": prog, "case": case, "result": result,
                 "cycles": int(m[1]) if m else "", "loads": int(m[2]) if m else "", "stores": int(m[3]) if m else "",
                 "imem_words": int(m[4]) if m else "", "note": fail.group(0).strip() if fail else ""})

(root / "results").mkdir(exist_ok=True)
with open(root / "results" / "cycles.csv", "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)

print(f"\n==== RTL 결과 요약 (F_MHZ={f_mhz:g}) -> results/cycles.csv ====")
print(f"{'program':24s} {'pass':>7s} {'mean cyc':>9s} {'max cyc':>8s} {'LD+ST':>6s} {'words':>5s} {'A_mem um2':>10s} {'P_mem mW':>9s} {'T_us':>8s}")
by = defaultdict(list)
for r in rows:
    by[r["program"]].append(r)
for prog, rs in by.items():
    ok = [r for r in rs if r["result"] == "PASS" and r["cycles"] != ""]
    if not ok:
        print(f"{prog:24s} {0:>3d}/{len(rs):<3d} (no passing run)")
        continue
    cyc = [r["cycles"] for r in ok]
    acc = sum(r["loads"] + r["stores"] for r in ok)
    words = ok[0]["imem_words"]
    cap, a_imem, e_imem = next(t for t in IMEM if words <= t[0])
    r_d = acc / sum(cyc)
    p_dyn = f_mhz / 1000 * (e_imem + E_DMEM * r_d)
    p_sta = 0.020 * (a_imem + DMEM_AREA) / 1000
    mean = sum(cyc) / len(cyc)
    print(f"{prog:24s} {len(ok):>3d}/{len(rs):<3d} {mean:9.1f} {max(cyc):8d} {acc:6d} {words:5d} {a_imem + DMEM_AREA:10.2f} {p_dyn + p_sta:9.4f} {mean / f_mhz:8.3f}")
    for r in rs:
        if r["result"] != "PASS":
            print(f"    FAIL {r['case']}: {r['note']}")
