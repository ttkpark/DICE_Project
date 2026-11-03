#!/usr/bin/env python3
"""주어진 .hex 를 cases/*.json 전부에 대해 Python ISA 모델(reference_run.run)로 실행한다.
검사: Y 정답, 허용 영역(Y/SCRATCH/DONE) 밖 store 금지, 입력·config 보존, Y 완료 후 DONE, 1~512 word.
    python3 tools/verify.py sw/int8_fast.hex    ->  results/functional_int8_fast.json
기준본의 고정 실행량 검사(verify_all.py)와 달리 어떤 프로그램에나 쓸 수 있다. 종료 코드 1 = FAIL."""
import json
import sys
from pathlib import Path
from reference_run import run, words

root = Path(__file__).resolve().parents[1]
prog = Path(sys.argv[1])
binary = words(prog)
if not 1 <= len(binary) <= 512:
    sys.exit(f"FAIL {prog.name}: {len(binary)} words (1~512 필요)")
rows = []
for case_path in sorted((root / "cases").glob("*.json")):
    case = json.loads(case_path.read_text(encoding="utf-8"))
    cfg = case["config"]
    initial = words(case_path.parent / case["memory_file"])
    allowed = {cfg["SCRATCH_BASE"] + 4 * i for i in range(32)} | {cfg["Y_BASE"] + 4 * i for i in range(4)} | {cfg["DONE_ADDR"]}
    errors, res = [], None
    try:
        res = run(binary, initial)          # DONE 전 Y 미완료·토큰 오류·불법 명령은 ValueError
        if res["outputs"] != case["expected_outputs"]:
            errors.append(f"Y={res['outputs']} expected={case['expected_outputs']}")
        bad = sorted({e["addr"] for e in res["store_events"]} - allowed)
        if bad:
            errors.append("store outside Y/SCRATCH/DONE: " + " ".join(f"0x{a:x}" for a in bad))
        if any(old != new and 4 * i not in allowed for i, (old, new) in enumerate(zip(initial, res["memory"]))):
            errors.append("input/config area modified")
    except ValueError as exc:
        errors.append(str(exc))
    row = {"case": case["name"], "pass": not errors, "errors": errors}
    if res:
        row.update(cycles=res["steps_to_done"], loads=res["data_loads"], stores=res["data_stores"], outputs=res["outputs"])
    rows.append(row)
    print(("PASS" if not errors else "FAIL"), f"{case['name']:17s}",
          f"cycles={row.get('cycles', '-'):>6} LD={row.get('loads', '-')} ST={row.get('stores', '-')}", " ".join(errors))

passed = sum(r["pass"] for r in rows)
done = [r["cycles"] for r in rows if "cycles" in r]
summary = {"program": prog.name, "imem_words": len(binary), "case_count": len(rows), "passed": passed,
           "mean_cycles": sum(done) / len(done) if done else None, "cases": rows,
           "scope": "Python ISA model. RTL cycle 은 run.sh / run.ps1 의 results/cycles.csv 참조"}
(root / "results").mkdir(exist_ok=True)
out = root / "results" / f"functional_{prog.stem}.json"
out.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"{prog.name}: {len(binary)} words, PASS {passed}/{len(rows)}, mean cycles {summary['mean_cycles']:.1f} -> {out.relative_to(root)}")
sys.exit(0 if passed == len(rows) else 1)
