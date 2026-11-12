#!/usr/bin/env python3
"""8개 실제 기계어를 실행하는 독립 ISA 기능 모델. RTL 합성/PPA 측정기는 아님."""
import argparse
import json
from pathlib import Path

MASK = 0xffffffff


def signed(value, bits):
    value &= (1 << bits) - 1
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def run(imem, initial_dmem, max_steps=100000):
    mem = initial_dmem.copy()
    regs = [0] * 32
    pc = steps = loads = stores = 0
    events = []
    done_addr, token = mem[0x31c // 4], mem[0x320 // 4]
    ybase, count = mem[0x30c // 4], mem[0x318 // 4]
    # 메모리 범위와 4바이트 정렬을 검사. word index는 byte_address >> 2.
    def index(addr):
        if addr % 4 or not 0 <= addr < len(mem) * 4:
            raise ValueError(f"잘못된 데이터 주소: 0x{addr:08x}")
        return addr >> 2

    for steps in range(1, max_steps + 1):
        if pc % 4 or not 0 <= pc // 4 < len(imem):
            raise ValueError(f"잘못된 PC: 0x{pc:08x}")
        ins = imem[pc >> 2]
        op, f3, f7 = ins & 0x7f, (ins >> 12) & 7, ins >> 25
        rd, rs1, rs2 = (ins >> 7) & 31, (ins >> 15) & 31, (ins >> 20) & 31
        a, b = regs[rs1], regs[rs2]
        nxt, result = (pc + 4) & MASK, None
        if op == 0x33:
            if (f7, f3) == (0, 0):
                result = a + b
            elif (f7, f3) == (0x20, 0):
                result = a - b
            elif (f7, f3) == (0, 7):
                result = a & b
            else:
                raise ValueError("미지원 R-type 기계어")
        elif op == 0x13 and f3 == 0:
            result = a + signed(ins >> 20, 12)
        elif op == 0x03 and f3 == 2:
            result = mem[index((a + signed(ins >> 20, 12)) & MASK)]
            loads += 1
        elif op == 0x23 and f3 == 2:
            imm = ((ins >> 25) << 5) | ((ins >> 7) & 31)
            addr = (a + signed(imm, 12)) & MASK
            mem[index(addr)] = b
            stores += 1
            events.append({"step": steps, "pc": pc, "addr": addr, "data": b})
            if addr == done_addr:
                if b != token:
                    raise ValueError("잘못된 DONE_TOKEN")
                ys = {ybase + 4 * j for j in range(count)}
                previous = {e["addr"] for e in events[:-1]}
                if not ys.issubset(previous):
                    raise ValueError("출력 store 완료 전 DONE 기록")
                return {"steps_to_done": steps, "instruction_fetches": steps,
                        "data_loads": loads, "data_stores": stores,
                        "outputs": [signed(mem[index(ybase + 4*j)], 32) for j in range(count)],
                        "store_events": events, "memory": mem}
        elif op == 0x63 and f3 == 0:
            imm = ((ins >> 31) << 12) | (((ins >> 7) & 1) << 11) | (((ins >> 25) & 63) << 5) | (((ins >> 8) & 15) << 1)
            if a == b:
                nxt = (pc + signed(imm, 13)) & MASK
        elif op == 0x6f:
            imm = ((ins >> 31) << 20) | (((ins >> 12) & 255) << 12) | (((ins >> 20) & 1) << 11) | (((ins >> 21) & 1023) << 1)
            result, nxt = pc + 4, (pc + signed(imm, 21)) & MASK
        else:
            raise ValueError(f"미지원 기계어 0x{ins:08x}, PC=0x{pc:08x}")
        if result is not None and rd:
            regs[rd] = result & MASK
        regs[0] = 0
        pc = nxt
    raise ValueError(f"{max_steps}개 명령 후에도 DONE 없음")


def words(path):
    return [int(line.strip(), 16) for line in Path(path).read_text(encoding="ascii").splitlines() if line.strip()]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--program", default="baseline_int8_fc_slow.hex")
    parser.add_argument("--case", default="cases/demo.json")
    parser.add_argument("--report")
    args = parser.parse_args()
    case_path = Path(args.case)
    case = json.loads(case_path.read_text(encoding="utf-8"))
    result = run(words(args.program), words(case_path.parent / case["memory_file"]))
    expected = case["expected_outputs"]
    if result["outputs"] != expected:
        raise SystemExit(f"FAIL: got {result['outputs']}, expected {expected}")
    result.pop("memory")
    result.update(case=case["name"], expected_outputs=expected, functional_pass=True,
                  metric_scope="기능 모델의 실행 명령 수. DC 실측 PPA가 아님")
    if args.report:
        Path(args.report).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PASS {case['name']}: Y={expected}, 명령 수={result['steps_to_done']}, LD={result['data_loads']}, ST={result['data_stores']}")


if __name__ == "__main__":
    main()
