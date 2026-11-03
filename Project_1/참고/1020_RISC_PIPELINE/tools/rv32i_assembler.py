#!/usr/bin/env python3
"""EE362 W07: eight-instruction RV32I teaching assembler (standard library only).

This translates assembly into instruction words. It does not compile C,
simulate a CPU, synthesize hardware, or implement the complete RV32I ISA.
"""
import argparse
import json
import re
import struct
import sys
from pathlib import Path

SUPPORTED = ("add", "sub", "and", "addi", "lw", "sw", "beq", "jal")
LABEL = re.compile(r"^[A-Za-z_][A-Za-z_0-9]*$")


class AssemblyError(ValueError):
    """입력 코드에 잘못된 명령·레지스터·즉시값이 있을 때 발생."""


def number(text):
    # 10진수 및 부호 있는 0x/0b 정수. 08도 10진수 8로 해석.
    try:
        return int(text, 10) if re.fullmatch(r"[+-]?\d+", text) else int(text, 0)
    except ValueError as exc:
        raise AssemblyError("정수 또는 라벨이 필요함: " + text) from exc


def register(text):
    # 처음 배우는 수업에서는 ABI 별칭 대신 x0~x31만 사용.
    match = re.fullmatch(r"x(\d+)", text.lower())
    if not match or not 0 <= int(match[1]) < 32:
        raise AssemblyError("레지스터는 x0~x31 형식으로 지정: " + text)
    return int(match[1])


def signed(value, bits):
    low, high = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    if not low <= value <= high:
        raise AssemblyError(f"{bits}비트 signed 범위 {low}~{high}를 벗어난 즉시값: {value}")
    return value & ((1 << bits) - 1)


def offset(text, pc, labels, bits):
    # 라벨은 '목적지 주소 - 현재 명령어 PC'. 숫자는 바이트 단위 상대 오프셋.
    value = labels[text] - pc if text in labels else number(text)
    signed(value, bits)
    # 이 수업은 32비트 명령어만 사용. C 확장(16비트 명령어)은 없음.
    if value % 4:
        raise AssemblyError("이 수업의 분기/점프 목적지는 4바이트 정렬 필요: " + text)
    if not 0 <= pc + value <= 0xFFFFFFFF:
        raise AssemblyError("분기/점프 목적지가 32비트 주소 범위를 벗어남")
    return value & ((1 << bits) - 1)


def memory_operand(text):
    match = re.fullmatch(r"([^()]+)\(\s*(x\d+)\s*\)", text.strip(), re.I)
    if not match:
        raise AssemblyError("메모리 피연산자는 offset(xN) 형식: " + text)
    return number(match[1].strip()), register(match[2])


def encode(line, pc, labels):
    parts = line.split(None, 1)
    op = parts[0].lower()
    if op not in SUPPORTED:
        raise AssemblyError("현재 W07 미지원 명령: " + op + " (지원: " + ", ".join(SUPPORTED) + ")")
    args = [item.strip() for item in parts[1].split(",")] if len(parts) == 2 else []
    count = 2 if op in ("lw", "sw", "jal") else 3
    if len(args) != count or any(not item for item in args):
        raise AssemblyError(f"{op}의 피연산자는 쉼표로 구분한 {count}개 필요")
    if op in ("add", "sub", "and"):
        rd, rs1, rs2 = map(register, args)
        funct7 = 0x20 if op == "sub" else 0
        funct3 = 7 if op == "and" else 0
        return funct7 << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | 0x33
    if op == "addi":
        rd, rs1 = register(args[0]), register(args[1])
        imm = signed(number(args[2]), 12)
        return imm << 20 | rs1 << 15 | rd << 7 | 0x13
    if op in ("lw", "sw"):
        reg = register(args[0])
        value, rs1 = memory_operand(args[1])
        imm = signed(value, 12)
        if op == "lw":
            return imm << 20 | rs1 << 15 | 2 << 12 | reg << 7 | 0x03
        # S-type: imm[11:5]와 imm[4:0]를 나누어 배치.
        return (imm >> 5) << 25 | reg << 20 | rs1 << 15 | 2 << 12 | (imm & 31) << 7 | 0x23
    if op == "beq":
        rs1, rs2 = register(args[0]), register(args[1])
        imm = offset(args[2], pc, labels, 13)
        # B-type: bit 0은 인코딩하지 않음. 오프셋은 여전히 '바이트' 단위.
        return ((imm >> 12) & 1) << 31 | ((imm >> 5) & 63) << 25 | rs2 << 20 | rs1 << 15 | ((imm >> 1) & 15) << 8 | ((imm >> 11) & 1) << 7 | 0x63
    rd = register(args[0])
    imm = offset(args[1], pc, labels, 21)
    # J-type: imm[20], [10:1], [11], [19:12] 순서의 실제 비트 배치.
    return ((imm >> 20) & 1) << 31 | ((imm >> 1) & 1023) << 21 | ((imm >> 11) & 1) << 20 | ((imm >> 12) & 255) << 12 | rd << 7 | 0x6F


def assemble(source, base=0):
    if not 0 <= base <= 0xFFFFFFFF or base % 4:
        raise AssemblyError("시작 PC는 32비트 범위의 4바이트 정렬 주소 필요")
    labels, instructions = {}, []
    pc = base
    # 1차: 각 라벨의 바이트 주소 계산. 명령어 하나당 PC는 4 증가.
    for lineno, original in enumerate(source.splitlines(), 1):
        line = re.split(r"#|//", original, maxsplit=1)[0].strip()
        while ":" in line:
            name, line = line.split(":", 1)
            name, line = name.strip(), line.strip()
            if not LABEL.fullmatch(name) or name in labels:
                raise AssemblyError(f"{lineno}행: 잘못되었거나 중복된 라벨: {name}")
            if pc > 0xFFFFFFFF:
                raise AssemblyError(f"{lineno}행: 라벨 주소 범위 초과")
            labels[name] = pc
        if line:
            if pc > 0xFFFFFFFC:
                raise AssemblyError(f"{lineno}행: 명령어 주소 범위 초과")
            instructions.append((lineno, pc, line))
            pc += 4
    if not instructions:
        raise AssemblyError("어셈블리 명령어가 없음")
    # 2차: 이제 앞으로 나오는 라벨까지 모두 해석 가능.
    result = []
    for lineno, pc, line in instructions:
        try:
            result.append({"line": lineno, "pc": pc, "assembly": line, "word": encode(line, pc, labels)})
        except AssemblyError as exc:
            raise AssemblyError(f"{lineno}행: {exc}") from exc
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="UTF-8 어셈블리 .s 파일")
    parser.add_argument("-o", "--output", type=Path, required=True, help="$readmemh용 HEX, 한 줄당 32비트 word")
    parser.add_argument("--listing", type=Path, help="바이트 PC, 기계어, 원문 확인용 목록")
    parser.add_argument("--bin", type=Path, help="선택: little-endian 바이트 파일")
    parser.add_argument("--base", type=number, default=0, help="첫 명령어의 바이트 PC (기본 0)")
    parser.add_argument("--json", type=Path, help="선택: 프로그램 인코딩 정보")
    args = parser.parse_args()
    try:
        records = assemble(args.source.read_text(encoding="utf-8-sig"), args.base)
        # 오류 검사를 모두 끝낸 다음에만 출력 생성.
        args.output.write_text("".join(f"{r['word']:08x}\n" for r in records), encoding="ascii")
        if args.listing:
            args.listing.write_text("".join(f"{r['pc']:08x}  {r['word']:08x}  {r['assembly']}\n" for r in records), encoding="utf-8")
        if args.bin:
            args.bin.write_bytes(b"".join(struct.pack("<I", r["word"]) for r in records))
        if args.json:
            args.json.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except (AssemblyError, OSError) as exc:
        parser.exit(1, "오류: " + str(exc) + "\n")
    print(f"{len(records)}개 명령 인코딩 완료: {args.output}")


if __name__ == "__main__":
    main()
