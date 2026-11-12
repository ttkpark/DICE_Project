# int8_fastv2.s : Y[j] = BIAS[j] + sum_i X[i]*W[j][i]  (N=8, M=4), 기본 8개 명령만 사용
#
# 방법 : X[i] 의 비트 k 가 1 이면 네 행의 acc_j 에 W[j][i]<<k 를 더한다 (bit 7 은 부호 비트이므로 뺀다).
#        W<<k 는 add w,w,w (doubling) 으로 만들고, 비트 검사는 and+beq 로 한다.
#        X 한 개의 비트 검사를 4개 행이 공유하므로 곱셈기 없이 (i,j) 쌍당 약 10 cycle.
#        곱한 즉시 누산하므로 SCRATCH 를 쓰지 않는다. 누산기는 BIAS 로 초기화한다.
#        i 루프는 2개씩 펼쳤다 (8 회 -> 4 회). 명령 191 word(원본 192) -> IMEM 256-word 구간.
#
# 레지스터
#   x1  X 포인터           x2  W 포인터 (W[0][i])   x3  X 끝 주소 (X_BASE+32)
#   x4  X[i]               x5~x8  W[0..3][i] (비트마다 2배)  x9~x12  acc0..3
#   x13~x20  비트 마스크 1,2,4,...,128     x21 임시      x22 DONE_TOKEN   x23 DONE_ADDR   x24 X[i+1]
#
# int8_fast 대비 바뀐 점 (알고리즘·분기 구조는 그대로, 193 word)
#   1. config 를 x0 기준 즉시값으로 읽어 addi x30 제거 (1 word, 1 cycle).
#   2. lw x21(BIAS_BASE) 바로 뒤에서 x21 을 쓰지 않게 상수 설정을 사이에 둠 (lw-use stall 1회 제거).
#   3. 두 번째 X 를 x24 에 읽음. "lw x4,4(x1)" 뒤의 "lw x5,4(x2)" 는 imm 비트(4)가 rs2 자리에서 x4 로 보여
#      EX 분기판의 lwStall 이 반복마다 1 cycle 을 버렸다 (ID 분기판은 원래 해당 없음).
#   4. 루프 끝 jal 뒤에 채움 명령 2개. 분기 이동 때 잘못 인출되는 done 의 lw 가 load 접근으로 세이지 않게 한다.

start:
    lw   x1, 768(x0)       # X_BASE   (configuration block 0x300 을 x0 기준으로 직접 읽음)
    lw   x2, 772(x0)       # W_BASE
    lw   x21, 776(x0)      # BIAS_BASE
    addi x3, x1, 32        # X 끝 = X_BASE + 8*4   (lw x21 과 BIAS load 사이에 상수 설정을 둬 lw-use stall 제거)
    addi x13, x0, 1
    addi x14, x0, 2
    addi x15, x0, 4
    addi x16, x0, 8
    addi x17, x0, 16
    addi x18, x0, 32
    addi x19, x0, 64
    addi x20, x0, 128
    lw   x9, 0(x21)        # acc0 = BIAS[0]
    lw   x10, 4(x21)       # acc1 = BIAS[1]
    lw   x11, 8(x21)       # acc2 = BIAS[2]
    lw   x12, 12(x21)      # acc3 = BIAS[3]

loop:
    # ---- X[i+0] ----
    lw   x4, 0(x1)
    lw   x5, 0(x2)        # W[0][i+0]
    lw   x6, 32(x2)        # W[1][i+0]
    lw   x7, 64(x2)        # W[2][i+0]
    lw   x8, 96(x2)        # W[3][i+0]
    and  x21, x4, x13        # bit 0
    beq  x21, x0, u0b0
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u0b0:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x4, x14        # bit 1
    beq  x21, x0, u0b1
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u0b1:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x4, x15        # bit 2
    beq  x21, x0, u0b2
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u0b2:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x4, x16        # bit 3
    beq  x21, x0, u0b3
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u0b3:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x4, x17        # bit 4
    beq  x21, x0, u0b4
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u0b4:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x4, x18        # bit 5
    beq  x21, x0, u0b5
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u0b5:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x4, x19        # bit 6
    beq  x21, x0, u0b6
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u0b6:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x4, x20        # bit 7 (부호 비트: 빼기)
    beq  x21, x0, u0b7
    sub  x9, x9, x5
    sub  x10, x10, x6
    sub  x11, x11, x7
    sub  x12, x12, x8
u0b7:
    # ---- X[i+1] ----
    lw   x24, 4(x1)       # x4 가 아닌 x24: 다음 lw 의 imm 비트(4)가 rd 와 겹치지 않게
    lw   x5, 4(x2)        # W[0][i+1]
    lw   x6, 36(x2)        # W[1][i+1]
    lw   x7, 68(x2)        # W[2][i+1]
    lw   x8, 100(x2)        # W[3][i+1]
    and  x21, x24, x13        # bit 0
    beq  x21, x0, u1b0
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u1b0:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x24, x14        # bit 1
    beq  x21, x0, u1b1
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u1b1:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x24, x15        # bit 2
    beq  x21, x0, u1b2
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u1b2:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x24, x16        # bit 3
    beq  x21, x0, u1b3
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u1b3:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x24, x17        # bit 4
    beq  x21, x0, u1b4
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u1b4:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x24, x18        # bit 5
    beq  x21, x0, u1b5
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u1b5:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x24, x19        # bit 6
    beq  x21, x0, u1b6
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
u1b6:
    add  x5, x5, x5
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    and  x21, x24, x20        # bit 7 (부호 비트: 빼기)
    beq  x21, x0, u1b7
    sub  x9, x9, x5
    sub  x10, x10, x6
    sub  x11, x11, x7
    sub  x12, x12, x8
u1b7:
    addi x1, x1, 8
    addi x2, x2, 8
    beq  x1, x3, done
    jal  x0, loop
    addi x0, x0, 0         # 실행되지 않는 자리 채움 2개: 위 jal/beq 가 이동할 때 잘못 인출되는 명령이
    addi x0, x0, 0         # done 의 lw 가 되지 않게 한다 (메모리 전력 계수기는 인출된 lw/sw 를 접근으로 센다)

done:
    lw   x21, 780(x0)       # Y_BASE
    lw   x22, 800(x0)      # DONE_TOKEN   (lw 를 먼저 모아 파이프라인 lw-use stall 제거)
    lw   x23, 796(x0)      # DONE_ADDR
    sw   x9, 0(x21)
    sw   x10, 4(x21)
    sw   x11, 8(x21)
    sw   x12, 12(x21)
    sw   x22, 0(x23)       # 모든 Y store 뒤 마지막 store
park:
    jal  x0, park
