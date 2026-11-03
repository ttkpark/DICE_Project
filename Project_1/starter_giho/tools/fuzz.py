#!/usr/bin/env python3
"""숨김 case 대비 랜덤 회귀. make_cases.py 와 같은 범위·주소 섞기로 case 를 만들어 Python ISA 모델로 돌린다.
    python3 tools/fuzz.py my.hex [N=1000] [seed=1]
검사: Y 정답, Y/SCRATCH/DONE 밖 store 금지, 입력·config 보존, DONE 순서(run 내부). 종료 코드 1 = FAIL."""
import random
import sys
from pathlib import Path
from reference_run import run, words

prog = words(sys.argv[1])
n = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
rng = random.Random(int(sys.argv[3]) if len(sys.argv) > 3 else 1)
EXTREME = [-128, -127, -1, 0, 1, 126, 127]
fails = 0
cyc = []
for t in range(n):
    # 1/4 은 극단값만 사용 (최대 누산, 부호 경계)
    pick = (lambda lo, hi: rng.choice([v for v in EXTREME if lo <= v <= hi])) if t % 4 == 0 else rng.randrange
    x = [pick(-128, 128) if t % 4 else rng.randrange(-128, 128) for _ in range(8)]
    if t % 4 == 0:
        x = [rng.choice(EXTREME) for _ in range(8)]
        w = [[rng.choice([-127, -1, 0, 1, 127]) for _ in range(8)] for _ in range(4)]
    else:
        w = [[rng.randrange(-127, 128) for _ in range(8)] for _ in range(4)]
    bias = [rng.randrange(-(1 << 30), (1 << 30) + 1) for _ in range(4)]
    slots = [0x000, 0x100, 0x200, 0x400, 0x500]
    rng.shuffle(slots)
    xb, wb, bb, yb, tb = slots
    token = rng.randrange(1, 1 << 32)
    mem = [0] * 512
    for base, vals in ((xb, x), (wb, sum(w, [])), (bb, bias)):
        for i, v in enumerate(vals):
            mem[base // 4 + i] = v & 0xffffffff
    for i in range(4):
        mem[yb // 4 + i] = 0x5a5a5a5a
    for i in range(32):
        mem[tb // 4 + i] = 0xa5a5a5a5
    for i, v in enumerate([xb, wb, bb, yb, tb, 8, 4, 0x3f0, token, 0x80000000]):
        mem[0x300 // 4 + i] = v
    expect = [bias[j] + sum(x[i] * w[j][i] for i in range(8)) for j in range(4)]
    allowed = {tb + 4 * i for i in range(32)} | {yb + 4 * i for i in range(4)} | {0x3f0}
    try:
        res = run(prog, mem)
        err = []
        if res["outputs"] != expect:
            err.append(f"Y={res['outputs']} expected={expect}")
        if {e["addr"] for e in res["store_events"]} - allowed:
            err.append("store outside allowed area")
        if any(o != nw and 4 * i not in allowed for i, (o, nw) in enumerate(zip(mem, res["memory"]))):
            err.append("input/config modified")
        cyc.append(res["steps_to_done"])
    except ValueError as exc:
        err = [str(exc)]
    if err:
        fails += 1
        print(f"FAIL #{t} x={x} w={w} bias={bias} :: {'; '.join(err)}")
print(f"{Path(sys.argv[1]).name}: {n - fails}/{n} PASS, cycles min/mean/max = {min(cyc)}/{sum(cyc)/len(cyc):.1f}/{max(cyc)}" if cyc else "no run")
sys.exit(1 if fails else 0)
