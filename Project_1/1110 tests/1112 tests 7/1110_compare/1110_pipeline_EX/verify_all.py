#!/usr/bin/env python3
"""패키지의 고정 기준 어셈블리 전체 기능 회귀. 공식 학생 채점 덱은 아님."""
import json
from pathlib import Path
from tools.reference_run import run, words
from tools.rv32i_assembler import assemble

root = Path(__file__).resolve().parent
records = assemble((root / "baseline_int8_fc_slow.s").read_text(encoding="utf-8"))
binary = words(root / "baseline_int8_fc_slow.hex")
assert binary == [r["word"] for r in records], "HEX가 소스와 불일치: 먼저 다시 인코딩"
results = []
for case_path in sorted((root / "cases").glob("*.json")):
    case = json.loads(case_path.read_text(encoding="utf-8"))
    initial = words(case_path.parent / case["memory_file"])
    before = initial.copy()
    res = run(binary, initial)
    assert res["outputs"] == case["expected_outputs"], case["name"]
    cfg = case["config"]
    allowed = {cfg["SCRATCH_BASE"] + 4*i for i in range(32)} | {cfg["Y_BASE"] + 4*i for i in range(4)} | {cfg["DONE_ADDR"]}
    assert all(e["addr"] in allowed for e in res["store_events"]), "허용되지 않은 쓰기"
    assert res["data_stores"] == 37, "SCRATCH 32 + Y 4 + DONE 1"
    assert res["data_loads"] == 110, "config 10 + X/W 64 + SCRATCH 32 + BIAS 4"
    assert initial == before, "실행 함수가 원본 fixture를 수정함"
    for idx, (old, new) in enumerate(zip(before, res["memory"])):
        assert old == new or idx*4 in allowed, "입력/config 손상"
    # 모든 입력/가중치는 두 보수 signed 값. W=0이면 곱 루프 본문을 실행하지 않음.
    expected_steps = 730 + 4 * sum(abs(v) for row in case["weights"] for v in row) + sum(v < 0 for row in case["weights"] for v in row)
    assert res["steps_to_done"] == expected_steps, "기준 소스의 실행 명령 수 산식과 불일치"
    results.append({"case": case["name"], "outputs": res["outputs"], "instructions": res["steps_to_done"],
                    "data_loads": res["data_loads"], "data_stores": res["data_stores"], "pass": True})
    print(f"PASS {case['name']}: {res['outputs']} / {res['steps_to_done']} instructions")
summary = {"scope": "RV32I 8명령 기능 모델 회귀. 물리 PPA 결과가 아님", "static_instructions": len(binary),
           "case_count": len(results), "passed": len(results), "cases": results}
(root / "FUNCTIONAL_VALIDATION.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"TOTAL PASS {len(results)}/{len(results)}")
