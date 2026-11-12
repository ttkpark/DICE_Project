#!/usr/bin/env python3
"""sim/tb_pj1.v 결과(build/pj1_*)를 ISA 모델과 비교하고, cycle 을 해저드 모델로 분해하고, PPA 표를 만든다.
    python3 tools/pj1_check.py [F_MHZ]          (run.sh / run.ps1 이 마지막에 자동 호출)

기능 판정 (하나라도 틀리면 FAIL, 종료 코드 1)
  1. TB 자체 PASS : 쓰기 범위, 4바이트 정렬, X 없음, Y 4개 완료 후 DONE, DONE 토큰, (있으면) Y 정답
  2. store 순서·주소·데이터가 ISA 모델(reference_run)과 1:1 동일   -> 순서 뒤바뀜, wrong-path store 를 잡는다
  3. DONE 시점 DMEM 512 word 전체가 ISA 모델과 동일                -> 입력·config 보존, SCRATCH 내용까지
  4. *__rst : 실행 도중 RESET 재인가 후 처음부터 같은 결과, 같은 cycle
cycle 모델 (판정 아님, 파이프라인이 설계대로 도는지 보는 근거)
  단일 사이클 : cycles = N                      N = ISA 모델의 실행 명령 수 (DONE sw 포함)
  5단 파이프  : cycles = N + 3 + S + 2B          3 = DONE sw 가 IF->MEM 가는 fill
                                                S = lw 바로 다음 명령의 rs1/rs2 필드 == lw.rd (CORE.v lwStall 과 같은 조건)
                                                B = taken BEQ + JAL (EX 에서 해결, 2 cycle flush)
  측정값이 어느 식과 정확히 같은지 표시한다. 파이프라인인데 둘 다 아니면 해저드 유닛이 설계와 다르게 동작하는 것.
  S 중 '가짜' = rs2 필드를 안 쓰는 명령(ADDI/LW/JAL)인데 필드 값이 우연히 같아서 생긴 stall (개선 여지).
PPA
  syn/reports/TOP_P<주기>/ (syn/run_synth.sh 결과, R1.4 TOP 합성) 가 있으면 setup·hold slack >= 0 인 최소 주기를 선언 f 로 삼아
  T = 평균 cycle / f,  A = CPU cell area + IMEM + DMEM,  P = CPU 전력 + 메모리 전력 (계약서 산식) 을 계산한다.
  없으면 인자 F_MHZ 로 메모리 몫만 계산한다.
SYN=CORE python3 tools/pj1_check.py : 비공식 CORE 단독 합성 결과(syn/reports/P*)로 PPA, results/pj1_summary_CORE.json 에 저장.
결과: results/pj1_summary.json.  옆 폴더(../1020_RISC*)에도 summary 가 있으면 나란히 비교표를 찍는다."""
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from reference_run import run, words  # noqa: E402

root = Path(__file__).resolve().parents[1]
PFX = "P" if os.environ.get("SYN") == "CORE" else "TOP_P"          # syn/reports 하위 폴더 접두어
SUMMARY = "pj1_summary_CORE.json" if PFX == "P" else "pj1_summary.json"
IMEM = [(64, 8713.50, 2.23), (256, 27352.30, 7.00), (512, 50667.68, 12.97)]
DMEM_AREA, E_DMEM = 50667.68, 12.97
UNIT = {"pW": 1e-9, "nW": 1e-6, "uW": 1e-3, "mW": 1.0, "W": 1e3}


def model(prog, case):
    imem = words(root / "sw" / f"{prog}.hex")
    r = run(imem, words(root / "cases" / f"{case}_dmem.hex"))
    pcs = r["pcs"]
    ins = [imem[p >> 2] for p in pcs]
    taken = sum(1 for k in range(len(pcs) - 1)
                if ins[k] & 0x7f == 0x6f or (ins[k] & 0x7f == 0x63 and pcs[k + 1] != pcs[k] + 4))
    s_hw = s_true = 0
    for a, b in zip(ins, ins[1:]):
        rd = a >> 7 & 31
        if a & 0x7f != 0x03 or rd == 0:
            continue
        rs1, rs2, op = b >> 15 & 31, b >> 20 & 31, b & 0x7f
        s_hw += rd in (rs1, rs2)
        s_true += (op != 0x6f and rs1 == rd) or (op in (0x33, 0x23, 0x63) and rs2 == rd)
    return {"n": len(pcs), "taken": taken, "s_hw": s_hw, "s_true": s_true,
            "loads": r["data_loads"], "stores": r["data_stores"],
            "trace": [(e["addr"], e["data"]) for e in r["store_events"]], "memory": r["memory"]}


def read_mem(path):
    vals, idx = [None] * 512, 0
    for line in path.read_text(errors="replace").splitlines():
        for tok in line.split("//")[0].split():
            if tok.startswith("@"):
                idx = int(tok[1:], 16)
                continue
            vals[idx] = int(tok, 16) if re.fullmatch(r"[0-9a-fA-F]+", tok) else None
            idx += 1
    return vals


def read_trace(path):
    lines = path.read_text().splitlines()
    if "R" in lines:
        lines = lines[len(lines) - lines[::-1].index("R"):]
    return [(int(a, 16), int(d, 16)) for _, a, d in (l.split() for l in lines if l.strip())]


def check(log):
    prog, case, *rst = log.stem[4:].split("__")
    text = log.read_text(errors="replace")
    row = {"program": prog, "case": case, "reset_test": bool(rst), "errors": []}
    m = re.search(r"PASS TB_PJ1: cycles=(\d+)", text)
    if not m:
        fail = re.search(r"^.*FAIL.*$", text, re.M)
        row["errors"].append(fail.group(0).strip() if fail else "TB 결과 없음 (로그 확인)")
        return row
    row["cycles"] = int(m[1])
    p = re.search(r"MEMORY_PPA cycles=\d+ LOAD=(\d+) STORE=(\d+) IMEM_words=(\d+)", text)
    if p:
        row.update(ppa_loads=int(p[1]), ppa_stores=int(p[2]), imem_words=int(p[3]))
    if rst and "RESET re-asserted" not in text:
        row["errors"].append("RESET 재인가 전에 DONE (RESET_AT 을 줄일 것)")
    try:
        ref = model(prog, case)
    except ValueError as exc:
        row["errors"].append(f"ISA 모델 오류: {exc}")
        return row
    row.update({k: ref[k] for k in ("n", "taken", "s_hw", "s_true", "loads", "stores")})
    got = read_trace(log.with_suffix(".trc"))
    if got != ref["trace"]:
        k = next((i for i, (g, e) in enumerate(zip(got, ref["trace"])) if g != e), min(len(got), len(ref["trace"])))
        g = f"{got[k][0]:x}<-{got[k][1]:08x}" if k < len(got) else "없음"
        e = f"{ref['trace'][k][0]:x}<-{ref['trace'][k][1]:08x}" if k < len(ref["trace"]) else "없음"
        row["errors"].append(f"store #{k} RTL {g} / 모델 {e} (RTL {len(got)}개, 모델 {len(ref['trace'])}개)")
    mem = read_mem(log.with_suffix(".mem"))
    bad = [i for i in range(512) if mem[i] != ref["memory"][i]]
    if bad:
        row["errors"].append(f"DMEM {len(bad)} word 불일치 (첫 주소 0x{4 * bad[0]:03x})")
    pipe = ref["n"] + 3 + ref["s_hw"] + 2 * ref["taken"]
    row["model"] = "single" if row["cycles"] == ref["n"] else "pipe5" if row["cycles"] == pipe else "other"
    return row


def parse_syn():
    sweep = []
    for d in sorted((root / "syn" / "reports").glob(PFX + "*")):
        try:
            period = float(d.name[len(PFX):])
            slack = lambda f: (lambda m: float(m[1]) if m else float("inf"))(
                re.search(r"slack \([^)]*\)\s+(-?[\d.]+)", (d / f).read_text(errors="replace")))
            qor = (d / "qor.rpt").read_text(errors="replace")
            pw = (d / "power_total.rpt").read_text(errors="replace")
            dyn = re.search(r"Total Dynamic Power\s*=\s*([\d.eE+-]+)\s*(\w+)", pw)
            leak = re.search(r"Cell Leakage Power\s*=\s*([\d.eE+-]+)\s*(\w+)", pw)
            sweep.append({"period": period, "setup": slack("timing_max.rpt"), "hold": slack("timing_min.rpt"),
                          "area": float(re.search(r"Cell Area:\s*([\d.]+)", qor)[1]),
                          "power": float(dyn[1]) * UNIT[dyn[2]] + float(leak[1]) * UNIT[leak[2]]})
        except (OSError, TypeError, KeyError):
            print(f"  (syn/reports/{d.name} 읽기 실패 - 건너뜀)")
    ok = [s for s in sweep if s["setup"] >= 0 and s["hold"] >= 0]
    return sweep, min(ok, key=lambda s: s["period"]) if ok else None


rows = [check(log) for log in sorted((root / "build").glob("pj1_*.log"))]
if not rows:
    sys.exit("build/pj1_*.log 없음: run.sh / run.ps1 을 먼저 실행")
fresh = {(r["program"], r["case"]): r.get("cycles") for r in rows if not r["reset_test"]}
for r in rows:
    if r["reset_test"] and "cycles" in r and r["cycles"] != fresh.get((r["program"], r["case"])):
        r["errors"].append(f"RESET 재인가 후 cycle {r['cycles']} != 처음 실행 {fresh.get((r['program'], r['case']))}")

sweep, best = parse_syn()
f_mhz = 1000 / best["period"] if best else (float(sys.argv[1]) if len(sys.argv) > 1 else 100.0)

print(f"\n==== PJ1 기능검사 (tb_pj1 + ISA 모델 비교) : {root.name} ====")
for r in rows:
    if r["errors"]:
        print(f"FAIL {r['program']:22s} {r['case'] + (' (reset)' if r['reset_test'] else ''):24s} " + " | ".join(r["errors"]))

by = defaultdict(list)
for r in rows:
    by[r["program"]].append(r)
summary = {"folder": root.name, "f_mhz": f_mhz, "syn": best, "programs": {}}
print(f"\n{'program':22s} {'기능':>7s} {'reset':>5s} {'평균cyc':>8s} {'명령N':>7s} {'CPI':>5s} "
      f"{'+fill':>5s} {'+lw':>6s} {'(가짜)':>6s} {'+분기':>7s} {'cycle모델':>10s}")
for prog, rs in by.items():
    main = [r for r in rs if not r["reset_test"]]
    ok = [r for r in main if not r["errors"]]
    rst = [r for r in rs if r["reset_test"]]
    rst_s = "-" if not rst else "OK" if all(not r["errors"] for r in rst) else "FAIL"
    if not ok:
        print(f"{prog:22s} {0:>3d}/{len(main):<3d} {rst_s:>5s}  (통과 run 없음)")
        summary["programs"][prog] = {"pass": 0, "cases": len(main)}
        continue
    mean = lambda k: sum(r[k] for r in ok) / len(ok)
    models = {r["model"] for r in ok}
    model_s = models.pop() if len(models) == 1 else "섞임"
    pipe = model_s != "single"
    cols = (f"{3:5d} {mean('s_hw'):6.1f} {mean('s_hw') - mean('s_true'):6.1f} {2 * mean('taken'):7.1f}"
            if pipe else f"{'-':>5s} {'-':>6s} {'-':>6s} {'-':>7s}")
    print(f"{prog:22s} {len(ok):>3d}/{len(main):<3d} {rst_s:>5s} {mean('cycles'):8.1f} {mean('n'):7.1f} "
          f"{mean('cycles') / mean('n'):5.2f} {cols} {model_s + ' ' + str(sum(r['model'] == model_s for r in ok)) + '/' + str(len(ok)):>10s}")
    p = {"pass": len(ok), "cases": len(main), "reset": rst_s, "model": model_s,
         "mean_cycles": mean("cycles"), "mean_n": mean("n"), "imem_words": ok[0].get("imem_words")}
    if "ppa_loads" in ok[0]:
        cyc = sum(r["cycles"] for r in ok)
        acc = sum(r["ppa_loads"] + r["ppa_stores"] for r in ok)
        _, a_imem, e_imem = next(t for t in IMEM if p["imem_words"] <= t[0])
        p_mem = f_mhz / 1000 * (e_imem + E_DMEM * acc / cyc) + 0.020 * (a_imem + DMEM_AREA) / 1000
        p.update(A_mem=a_imem + DMEM_AREA, P_mem=p_mem, T_us=p["mean_cycles"] / f_mhz)
        if best:
            p.update(A=best["area"] + p["A_mem"], P=best["power"] + p_mem)
    summary["programs"][prog] = p

print(f"\n==== PPA ({'선언 f = DC 최소 주기 ' + format(best['period'], 'g') + ' ns' if best else 'CPU 합성 결과 없음: 메모리 몫만'}, "
      f"f = {f_mhz:.1f} MHz) ====")
if sweep:
    print("  DC 주기 탐색: " + "  ".join(f"{s['period']:g}ns setup {s['setup']:+.3f} hold {s['hold']:+.3f}" for s in sweep))
    if best:
        print(f"  CPU cell area {best['area']:.1f} um2, CPU power {best['power']:.4f} mW @ {f_mhz:.1f} MHz")
print(f"{'program':22s} {'words':>5s} {'T_us':>8s} {'A_mem um2':>10s} {'P_mem mW':>9s}" + (f" {'A um2':>10s} {'P mW':>9s}" if best else ""))
for prog, p in summary["programs"].items():
    if "T_us" in p:
        print(f"{prog:22s} {p['imem_words']:5d} {p['T_us']:8.3f} {p['A_mem']:10.1f} {p['P_mem']:9.4f}"
              + (f" {p['A']:10.1f} {p['P']:9.4f}" if best else ""))

(root / "results").mkdir(exist_ok=True)
(root / "results" / SUMMARY).write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

others = [json.loads(f.read_text(encoding="utf-8")) for f in sorted(root.parent.glob("*/results/" + SUMMARY))
          if f.parents[1] != root]
for o in others:
    print(f"\n==== 비교 : {root.name} (f={f_mhz:.1f} MHz)  vs  {o['folder']} (f={o['f_mhz']:.1f} MHz) ====")
    print(f"{'program':22s} {'cyc 이쪽':>9s} {'cyc 저쪽':>9s} {'cyc비':>6s} {'T 이쪽':>8s} {'T 저쪽':>8s}"
          + (f" {'A 이쪽':>9s} {'A 저쪽':>9s} {'P 이쪽':>8s} {'P 저쪽':>8s}" if best and o.get("syn") else ""))
    for prog, p in summary["programs"].items():
        q = o["programs"].get(prog)
        if not q or "T_us" not in p or "T_us" not in q:
            continue
        line = (f"{prog:22s} {p['mean_cycles']:9.1f} {q['mean_cycles']:9.1f} {p['mean_cycles'] / q['mean_cycles']:6.3f} "
                f"{p['T_us']:8.3f} {q['T_us']:8.3f}")
        if best and o.get("syn"):
            line += f" {p['A']:9.0f} {q['A']:9.0f} {p['P']:8.3f} {q['P']:8.3f}"
        print(line)
    print("  cyc비 = 이쪽/저쪽. 이쪽이 T 에서 이기려면 f_이쪽/f_저쪽 > cyc비 (같은 f 가정 T 비교는 합성 전 참고용)")

failed = sum(bool(r["errors"]) for r in rows)
print(f"\nPJ1_CHECK {'PASS' if not failed else 'FAIL'} {len(rows) - failed}/{len(rows)} runs -> results/{SUMMARY}")
sys.exit(1 if failed else 0)
