#!/usr/bin/env python3
"""수업용 INT8 커널 입력 및 곱셈으로 직접 계산한 독립 정답 생성."""
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build(name, x, w, bias, seed):
    assert len(x) == 8 and len(w) == 4 and all(len(row) == 8 for row in w)
    assert all(-128 <= v <= 127 for v in x)
    assert all(-127 <= v <= 127 for row in w for v in row)
    assert all(-(1 << 30) <= v <= (1 << 30) for v in bias)
    slots = [0x000, 0x100, 0x200, 0x400, 0x500]
    rng = random.Random(seed)
    rng.shuffle(slots)
    xb, wb, bb, yb, tb = slots
    token = rng.randrange(1, 1 << 32)
    mem = [0] * 512
    for base, values in ((xb, x), (wb, sum(w, [])), (bb, bias)):
        for i, value in enumerate(values):
            mem[base // 4 + i] = value & 0xffffffff
    # 초기 출력은 sentinel로 채워, 누락된 store가 우연히 0과 일치하지 않도록 함.
    for i in range(4):
        mem[yb // 4 + i] = 0x5a5a5a5a
    for i in range(32):
        mem[tb // 4 + i] = 0xa5a5a5a5
    config = [xb, wb, bb, yb, tb, 8, 4, 0x3f0, token, 0x80000000]
    for i, value in enumerate(config):
        mem[0x300 // 4 + i] = value
    out = [bias[j] + sum(x[i] * w[j][i] for i in range(8)) for j in range(4)]
    assert all(-(1 << 31) <= v < (1 << 31) for v in out)
    folder = ROOT / "cases"
    folder.mkdir(exist_ok=True)
    (folder / f"{name}_dmem.hex").write_text("".join(f"{v:08x}\n" for v in mem), encoding="ascii")
    (folder / f"{name}_expected.hex").write_text("".join(f"{v & 0xffffffff:08x}\n" for v in out), encoding="ascii")
    data = {"name": name, "seed": seed, "memory_file": f"{name}_dmem.hex", "expected_file": f"{name}_expected.hex",
            "input": x, "weights": w, "bias": bias, "expected_outputs": out,
            "config": dict(zip(("X_BASE", "W_BASE", "BIAS_BASE", "Y_BASE", "SCRATCH_BASE", "N", "M", "DONE_ADDR", "DONE_TOKEN", "SIGN_MASK"), config))}
    (folder / f"{name}.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    demo_x = [-3, 1, 2, -1, 0, 4, -2, 3]
    demo_w = [[1, -2, 3, 0, 1, -1, 2, 1], [-1, 1, 0, 2, -2, 3, 1, -1],
              [0, 1, -1, 1, 2, 0, -3, 2], [2, 0, -2, 1, -1, 1, 0, -1]]
    build("demo", demo_x, demo_w, [10, -5, 0, 100], 362)
    build("zero_weights", demo_x, [[0] * 8 for _ in range(4)], [17, -17, 0, 123], 1)
    build("max_positive", [127] * 8, [[127] * 8 for _ in range(4)], [0, 1, -1, 4096], 2)
    build("negative_extreme", [-128] * 8, [[-127] * 8 for _ in range(4)], [0, 1, -1, -4096], 3)
    build("mixed_sign", [-128, -127, -1, 0, 1, 2, 126, 127],
          [[-127, 127, -1, 0, 1, -2, 126, -126] for _ in range(4)], [-50, 50, 0, 999], 4)
    build("large_bias", demo_x, demo_w, [1 << 30, -(1 << 30), 999999, -999999], 5)
    for k in range(10):
        rng = random.Random(36200 + k)
        build(f"random_{k:02d}", [rng.randrange(-128, 128) for _ in range(8)],
              [[rng.randrange(-127, 128) for _ in range(8)] for _ in range(4)],
              [rng.randrange(-1000000, 1000001) for _ in range(4)], 36200 + k)
    print("16개 입력/독립 정답/주소 배치 생성 완료")


if __name__ == "__main__":
    main()
