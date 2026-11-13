#!/usr/bin/env python3
"""Project 1에서 허용된 37개 기계어를 실행하는 공개 기능 모델."""
import argparse
import json
from operator import add, and_, eq, ge, lt, ne, or_, sub, xor
from pathlib import Path

MASK = 0xffffffff


def signed(value, bits):
    value &= (1 << bits) - 1
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def signed_less(a, b):
    return signed(a, 32) < signed(b, 32)


def signed_ge(a, b):
    return signed(a, 32) >= signed(b, 32)


def shift_left(a, b):
    return a << (b & 31)


def shift_right(a, b):
    return a >> (b & 31)


def shift_arithmetic(a, b):
    return signed(a, 32) >> (b & 31)


REG_ALU = {
    (0, 0): add, (0x20, 0): sub, (0, 1): shift_left,
    (0, 2): signed_less, (0, 3): lt, (0, 4): xor,
    (0, 5): shift_right, (0x20, 5): shift_arithmetic, (0, 6): or_, (0, 7): and_,
}
IMM_ALU = {0: add, 2: signed_less, 3: lt, 4: xor, 6: or_, 7: and_}
BRANCH = {0: eq, 1: ne, 4: signed_less, 5: signed_ge, 6: lt, 7: ge}
LOAD = {0: (1, True), 1: (2, True), 2: (4, False), 4: (1, False), 5: (2, False)}
STORE = {0: 1, 1: 2, 2: 4}


def run(imem, initial_dmem, max_steps=100000):
    mem = initial_dmem.copy()
    regs = [0] * 32
    pc = steps = loads = stores = 0
    events = []
    done_addr, token = mem[0x31c // 4], mem[0x320 // 4]
    ybase, count = mem[0x30c // 4], mem[0x318 // 4]
    # 자연 정렬을 검사한 뒤 little-endian word와 바이트 위치를 계산.
    def index(addr, size=4):
        if addr % size or not 0 <= addr <= len(mem) * 4 - size:
            raise ValueError(f"잘못된 {size}바이트 데이터 접근: 0x{addr:08x}")
        return addr >> 2

    for steps in range(1, max_steps + 1):
        if pc % 4 or not 0 <= pc // 4 < len(imem):
            raise ValueError(f"잘못된 PC: 0x{pc:08x}")
        ins = imem[pc >> 2]
        op, f3, f7 = ins & 0x7f, (ins >> 12) & 7, ins >> 25
        rd, rs1, rs2 = (ins >> 7) & 31, (ins >> 15) & 31, (ins >> 20) & 31
        a, b = regs[rs1], regs[rs2]
        nxt, result = (pc + 4) & MASK, None
        if op == 0x33 and (f7, f3) in REG_ALU:
            result = REG_ALU[f7, f3](a, b)
        elif op == 0x13 and f3 in IMM_ALU:
            result = IMM_ALU[f3](a, signed(ins >> 20, 12) & MASK)
        elif op == 0x13 and f3 in (1, 5) and (f7, f3) in REG_ALU:
            result = REG_ALU[f7, f3](a, rs2)
        elif op in (0x17, 0x37):
            result = (ins & 0xfffff000) + (pc if op == 0x17 else 0)
        elif op == 0x03 and f3 in LOAD:
            size, extend_sign = LOAD[f3]
            addr = (a + signed(ins >> 20, 12)) & MASK
            bits = size * 8
            value = (mem[index(addr, size)] >> ((addr & 3) * 8)) & ((1 << bits) - 1)
            result = signed(value, bits) if extend_sign else value
            loads += 1
        elif op == 0x23 and f3 in STORE:
            imm = ((ins >> 25) << 5) | ((ins >> 7) & 31)
            addr = (a + signed(imm, 12)) & MASK
            size = STORE[f3]
            word_index = index(addr, size)
            lane = (addr & 3) * 8
            mask = ((1 << (size * 8)) - 1) << lane
            data = (mem[word_index] & ~mask) | ((b << lane) & mask)
            mem[word_index] = data
            stores += 1
            # 고정 DMEM 인터페이스에는 정렬된 주소와 병합된 32비트 word가 전달됨.
            bus_addr = addr & ~3
            events.append({"step": steps, "pc": pc, "addr": bus_addr, "data": data})
            if bus_addr == done_addr:
                if data != token:
                    raise ValueError("잘못된 DONE_TOKEN")
                ys = {ybase + 4 * j for j in range(count)}
                previous = {e["addr"] for e in events[:-1]}
                if not ys.issubset(previous):
                    raise ValueError("출력 store 완료 전 DONE 기록")
                return {"steps_to_done": steps, "instruction_fetches": steps,
                        "data_loads": loads, "data_stores": stores,
                        "outputs": [signed(mem[index(ybase + 4*j)], 32) for j in range(count)],
                        "store_events": events, "memory": mem}
        elif op == 0x63 and f3 in BRANCH:
            imm = ((ins >> 31) << 12) | (((ins >> 7) & 1) << 11) | (((ins >> 25) & 63) << 5) | (((ins >> 8) & 15) << 1)
            if BRANCH[f3](a, b):
                nxt = (pc + signed(imm, 13)) & MASK
        elif op == 0x6f:
            imm = ((ins >> 31) << 20) | (((ins >> 12) & 255) << 12) | (((ins >> 20) & 1) << 11) | (((ins >> 21) & 1023) << 1)
            result, nxt = pc + 4, (pc + signed(imm, 21)) & MASK
        elif op == 0x67 and f3 == 0:
            result, nxt = pc + 4, ((a + signed(ins >> 20, 12)) & MASK) & ~1
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
