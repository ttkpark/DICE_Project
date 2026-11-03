# int8_small.s : int8_fast.s 와 같은 알고리즘을 비트 루프로 접어 64 word 안에 넣은 판
#                (IMEM 64-word 구간 유지: 면적·정적전력 최소, 대신 cycle 은 fast 보다 많음)
#
# 레지스터
#   x1  X 포인터     x2  W 포인터 (W[0][i])   x3  X 끝 주소
#   x4  X[i]         x5~x8  W[0..3][i] (비트마다 2배)    x9~x12 acc0..3
#   x13 비트 마스크 (1 부터 2배씩)   x14 상수 128   x21 임시   x22 DONE_TOKEN   x30 config

start:
    addi x30, x0, 768      # configuration block
    lw   x1, 0(x30)        # X_BASE
    lw   x2, 4(x30)        # W_BASE
    lw   x21, 8(x30)       # BIAS_BASE
    lw   x9, 0(x21)        # acc0 = BIAS[0]
    lw   x10, 4(x21)       # acc1 = BIAS[1]
    lw   x11, 8(x21)       # acc2 = BIAS[2]
    lw   x12, 12(x21)      # acc3 = BIAS[3]
    addi x3, x1, 32        # X 끝 = X_BASE + 8*4
    addi x14, x0, 128      # 부호 비트 마스크

loop_i:
    lw   x4, 0(x1)         # X[i]
    lw   x5, 0(x2)         # W[0][i]
    lw   x6, 32(x2)        # W[1][i]
    lw   x7, 64(x2)        # W[2][i]
    lw   x8, 96(x2)        # W[3][i]
    addi x13, x0, 1        # 비트 0 부터

loop_bit:                  # 비트 0..6 : X 비트가 1 이면 acc_j += W_j<<k
    and  x21, x4, x13
    beq  x21, x0, skip_add
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
skip_add:
    add  x5, x5, x5        # W_j <<= 1
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    add  x13, x13, x13     # 마스크 <<= 1
    beq  x13, x14, bit7
    jal  x0, loop_bit

bit7:                      # 비트 7 은 부호 비트 (-128) : acc_j -= W_j<<7
    and  x21, x4, x14
    beq  x21, x0, next_i
    sub  x9, x9, x5
    sub  x10, x10, x6
    sub  x11, x11, x7
    sub  x12, x12, x8
next_i:
    addi x1, x1, 4
    addi x2, x2, 4
    beq  x1, x3, done
    jal  x0, loop_i

done:
    lw   x21, 12(x30)      # Y_BASE
    sw   x9, 0(x21)
    sw   x10, 4(x21)
    sw   x11, 8(x21)
    sw   x12, 12(x21)
    lw   x21, 28(x30)      # DONE_ADDR
    lw   x22, 32(x30)      # DONE_TOKEN
    sw   x22, 0(x21)       # 모든 Y store 뒤 마지막 store
park:
    jal  x0, park
