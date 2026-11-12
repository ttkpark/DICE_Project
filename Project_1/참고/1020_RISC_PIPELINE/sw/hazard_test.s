# hazard_test.s : 파이프라인 해저드 지향 시험 (기본 8명령만). INT8 프로그램과 같은 config 블록(0x300)을 쓴다.
#   중간 결과를 SCRATCH 에, 마지막에 Y 4 word 와 DONE 을 쓴다.
#   정답은 따로 없다: tools/pj1_check.py 가 ISA 모델(reference_run)의 store 순서·값·최종 DMEM 과 비교한다.
#   분기 그림자(wrong-path)에는 config 영역(0x300) store 를 넣었다 -> flush 가 안 되면 TB 쓰기범위 검사에서 바로 FAIL.
#
# 레지스터: x31 SCRATCH_BASE  x29 Y_BASE  x28 DONE_ADDR  x27 DONE_TOKEN  x30 config

start:
    addi x30, x0, 768        # config
    lw   x31, 16(x30)        # SCRATCH_BASE
    lw   x29, 12(x30)        # Y_BASE
    lw   x28, 28(x30)        # DONE_ADDR
    lw   x27, 32(x30)        # DONE_TOKEN

# 1) MEM -> EX, WB -> EX 포워딩 (rs1, rs2 각각)
    addi x1, x0, 5
    addi x2, x0, 7
    add  x3, x1, x2          # x2 MEM 포워딩, x1 WB 포워딩 -> 12
    sub  x4, x3, x1          # x3 MEM (rs1)              -> 7
    and  x5, x4, x3          # x4 MEM, x3 WB             -> 4
    sw   x5, 0(x31)

# 2) WB -> ID write-first (3 명령 뒤 읽기)
    addi x6, x0, 9
    add  x0, x0, x0
    add  x0, x0, x0
    add  x7, x6, x6          # 18
    sw   x7, 4(x31)

# 3) store 데이터(rs2)·주소(rs1) 포워딩
    addi x8, x0, -3
    sw   x8, 8(x31)
    addi x9, x31, 12
    sw   x8, 0(x9)

# 4) lw-use stall : rs1, rs2, store 데이터, store 주소.  거리 2 는 stall 없이 WB 포워딩
    lw   x10, 0(x31)         # 4
    add  x11, x10, x1        # rs1 -> 9
    lw   x12, 4(x31)         # 18
    sub  x13, x1, x12        # rs2 -> -13
    lw   x14, 8(x31)         # -3
    sw   x14, 16(x31)        # store 데이터
    sw   x31, 20(x31)
    lw   x15, 20(x31)        # SCRATCH_BASE
    sw   x13, 24(x15)        # store 주소
    lw   x16, 0(x31)
    add  x0, x0, x0
    add  x17, x16, x16       # 거리 2 -> 8
    sw   x17, 28(x31)

# 5) 분기 : 포워딩된 값 비교, taken / not taken, lw 직후 분기, taken 분기 그림자의 분기
    addi x18, x0, 4
    addi x19, x0, 4
    beq  x18, x19, b1        # 두 피연산자 모두 포워딩, taken
    sw   x18, 0(x30)         # wrong-path
    sw   x18, 0(x30)         # wrong-path
b1:
    addi x20, x0, 1
    beq  x20, x0, bad        # not taken
    sw   x20, 32(x31)
    lw   x21, 0(x31)         # 4
    beq  x21, x5, b2         # lw-use stall 뒤 taken
    sw   x21, 0(x30)         # wrong-path
b2:
    beq  x0, x0, b3
    beq  x0, x0, bad         # 그림자 안의 분기 -> 무시돼야 함
    sw   x0, 0(x30)          # wrong-path
b3:

# 6) JAL 링크 값 바로 사용 (MEM 단계 PC+4 포워딩)
    jal  x22, j1
    sw   x0, 0(x30)          # wrong-path
j1:
    sw   x22, 36(x31)        # 링크 값을 store 데이터로
    jal  x23, j2
j2:
    add  x24, x23, x0        # 링크 값을 바로 ALU 입력으로
    sw   x24, 40(x31)

# 7) x0 목적지는 포워딩·stall 대상이 아니어야 함
    addi x0, x0, 5
    add  x25, x0, x0         # 0
    sw   x25, 44(x31)
    lw   x0, 0(x31)
    add  x26, x0, x1         # 5
    sw   x26, 48(x31)

# 8) 뒤로 가는 루프 3회
    addi x16, x0, 3
    addi x17, x0, 0
loop:
    addi x16, x16, -1
    add  x17, x17, x16       # 2+1+0 = 3
    beq  x16, x0, out
    jal  x0, loop
out:
    sw   x17, 52(x31)

# Y 4 word -> DONE
    sw   x3, 0(x29)
    sw   x11, 4(x29)
    sw   x24, 8(x29)
    sw   x17, 12(x29)
    sw   x27, 0(x28)
park:
    jal  x0, park
bad:
    sw   x0, 0(x30)          # 여기 오면 쓰기범위 FAIL
    jal  x0, park
