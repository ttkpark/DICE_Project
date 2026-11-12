# int8_opt64.s : Y[j] = BIAS[j] + sum_i X[i]*W[j][i]  (N=8, M=4), 기본 8개 명령만 사용, 58 word (IMEM 64 구간)
#
# 알고리즘 (int8_small/int8_fast 와 같은 비트 직렬 곱):
#   X[i] 의 비트 k 가 1 이면 네 행의 acc_j 에 W[j][i]<<k 를 더한다 (bit 7 은 부호 비트라 뺀다).
#   W<<k 는 add w,w,w (doubling), 비트 검사는 and+beq. X 하나의 비트 검사를 4개 행이 공유한다.
#   누산기는 BIAS 로 시작하고 SCRATCH 는 쓰지 않는다 (store = Y 4 + DONE 1, load = 50).
#
# int8_small(48 word, 609+4p cycle) 대비 바뀐 점
#   1. 비트 루프를 2비트씩 펼치고 종료 검사(mask==128)를 두 비트 사이에 둔다.
#        1~3회차: bit(2n) [검사 통과] bit(2n+1) jal      4회차: bit6 [mask=128 -> 탈출] -> bit7(부호, sub)
#      비트 루프의 beq/jal 오버헤드가 i 당 13회 -> 7회.
#   2. i 루프 종료 검사를 루프 머리로 옮기고, 부호 비트가 0 이면 bit7 의 beq 가 바로 다음 i 로 간다
#      (next_i 블록의 beq+jal 제거: X>=0 인 i 마다 1 cycle, 파이프라인은 taken 분기 1회 = 3 cycle 절약).
#   3. configuration block(0x300) 은 x0 기준 즉시값(768..800)으로 직접 읽어 base 레지스터 설정 1 word·1 cycle 절약.
#   4. lw 바로 다음 명령이 그 결과를 쓰지 않도록 배치 (5단 파이프라인 lw-use stall 0회).
#   => 단일 사이클 554 + 4p + n  (p = sum_i popcount(X[i] & 0xFF) 0..64, n = 음수 X 개수 0..8)
#      int8_small 은 609 + 4p.
#
# 레지스터
#   x1 X 포인터   x2 W 포인터(W[0][i])   x3 X 끝 주소(X_BASE+32)   x4 X[i]
#   x5~x8 W[0..3][i] (비트마다 2배)   x9~x12 acc0..3   x13 비트 마스크   x14 상수 128
#   x21 임시(BIAS_BASE/Y_BASE/비트검사)   x22 DONE_TOKEN   x23 DONE_ADDR

start:
    lw   x1, 768(x0)       # X_BASE
    lw   x2, 772(x0)       # W_BASE
    lw   x21, 776(x0)      # BIAS_BASE
    addi x3, x1, 32        # X 끝 = X_BASE + 8*4
    addi x14, x0, 128      # 루프 종료 비교값 = 부호 비트 마스크
    lw   x9, 0(x21)        # acc0 = BIAS[0]
    lw   x10, 4(x21)       # acc1 = BIAS[1]
    lw   x11, 8(x21)       # acc2 = BIAS[2]
    lw   x12, 12(x21)      # acc3 = BIAS[3]

loop_i:
    beq  x1, x3, done      # 8개 X 를 모두 처리했으면 종료 (i 루프 검사를 머리에 둠)
    lw   x4, 0(x1)         # X[i]
    lw   x5, 0(x2)         # W[0][i]
    lw   x6, 32(x2)        # W[1][i]
    lw   x7, 64(x2)        # W[2][i]
    lw   x8, 96(x2)        # W[3][i]
    addi x13, x0, 1        # 비트 0 부터

loop_bit:                  # 한 바퀴에 비트 2개. 4회차는 첫 비트(bit6) 뒤 탈출
    and  x21, x4, x13      # --- 짝수 비트
    beq  x21, x0, skip_a
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
skip_a:
    add  x5, x5, x5        # W_j <<= 1
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    add  x13, x13, x13     # 마스크 <<= 1
    beq  x13, x14, bit7    # mask 2,8,32: 통과 / 128: 부호 비트로 (이때 W_j = W_j<<7)
    and  x21, x4, x13      # --- 홀수 비트
    beq  x21, x0, skip_b
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
skip_b:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    add  x13, x13, x13
    jal  x0, loop_bit

bit7:                      # 비트 7 은 부호 비트 (-128) : acc_j -= W_j<<7
    addi x1, x1, 4         # 포인터는 먼저 올려 두고 (X/W 는 이미 레지스터에 있음)
    addi x2, x2, 4
    and  x21, x4, x13
    beq  x21, x0, loop_i   # X >= 0 이면 바로 다음 i 로 (분기 1회 절약)
    sub  x9, x9, x5
    sub  x10, x10, x6
    sub  x11, x11, x7
    sub  x12, x12, x8
    jal  x0, loop_i

done:
    lw   x21, 780(x0)      # Y_BASE
    lw   x22, 800(x0)      # DONE_TOKEN
    lw   x23, 796(x0)      # DONE_ADDR
    sw   x9, 0(x21)
    sw   x10, 4(x21)
    sw   x11, 8(x21)
    sw   x12, 12(x21)
    sw   x22, 0(x23)       # 모든 Y store 뒤 마지막 store
park:
    jal  x0, park
