# int8_opt64v2.s : Y[j] = BIAS[j] + sum_i X[i]*W[j][i]  (N=8, M=4), 기본 8개 명령만 사용, 63 word (IMEM 64 구간)
#
# 알고리즘은 int8_opt64 와 같다 (비트 직렬 곱, 2비트씩 펼친 루프, bit 7 은 부호 비트라 뺀다).
# 명령 수(ISA)는 그대로 두고 파이프라인에서 버려지는 cycle 만 줄였다. EX 분기판·ID 분기판 공용.
#
# int8_opt64 대비 바뀐 점
#   1. 비트 루프 끝의 jal 앞에 다음 짝수 비트 검사(and+beq)를 복제했다.
#        다음 비트가 0 이면 beq 가 곧바로 skip_a 로 간다 -> jal 을 실행하지 않는다.
#        (원래: jal -> and -> beq taken.  지금: and -> beq taken.  bit 2,4,6 이 0 일 때마다 jal 1회 절약)
#        다음 비트가 1 이면 jal add_a 로 가서 원래와 같은 비용.
#   2. bit7 블록을 loop_i 바로 앞에 두어 X<0 일 때 sub 4개 뒤 jal 없이 loop_i 로 떨어진다.
#        대신 시작부에서 loop_i 로 가는 jal 을 한 번 실행한다 (음수 X 가 2개 이상이면 이득).
#   3. 마스크 2배(add x13)를 비트 검사 and 와 beq 사이로 옮겼다.
#        EX->ID 전달이 없는 ID 분기 구조에서도 "beq 직전 명령이 피연산자를 씀" 이 한 번도 없다.
#        (EX 분기판, EX->ID 전달이 있는 ID 분기판에서는 cycle 영향 없음)
#   4. 루프 끝 jal 뒤에 채움 명령 2개. 분기 이동 때 잘못 인출되는 done 의 lw 가 load 접근으로 세이지 않게 한다.
#   lw 바로 다음 명령이 그 결과를 쓰는 곳 없음. lw 다음 명령의 rs1/rs2 자리 비트가 lw 의 rd 와 겹치는 곳도 없음.
#
# 레지스터 (int8_opt64 와 동일)
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
    jal  x0, loop_i        # 한 번만 실행

bit7:                      # 비트 7 은 부호 비트 (-128) : acc_j -= W_j<<7   (여기서 x13 = 128)
    and  x21, x4, x13
    addi x1, x1, 4         # 포인터를 올린다 (X/W 는 이미 레지스터에 있음)
    addi x2, x2, 4
    beq  x21, x0, loop_i   # X >= 0 이면 뺄셈을 건너뛴다
    sub  x9, x9, x5
    sub  x10, x10, x6
    sub  x11, x11, x7
    sub  x12, x12, x8      # 뒤이어 loop_i 로 떨어진다 (jal 없음)

loop_i:
    beq  x1, x3, done      # 8개 X 를 모두 처리했으면 종료
    lw   x4, 0(x1)         # X[i]
    lw   x5, 0(x2)         # W[0][i]
    lw   x6, 32(x2)        # W[1][i]
    lw   x7, 64(x2)        # W[2][i]
    lw   x8, 96(x2)        # W[3][i]
    addi x13, x0, 1        # 비트 0 부터

    and  x21, x4, x13      # --- 짝수 비트 검사 (i 마다 첫 회만 여기로, 이후는 루프 끝의 복제본)
    add  x13, x13, x13     # 마스크 <<= 1
    beq  x21, x0, skip_a
add_a:
    add  x9, x9, x5
    add  x10, x10, x6
    add  x11, x11, x7
    add  x12, x12, x8
skip_a:
    add  x5, x5, x5        # W_j <<= 1
    add  x6, x6, x6
    add  x7, x7, x7
    add  x8, x8, x8
    beq  x13, x14, bit7    # mask 2,8,32: 통과 / 128: 부호 비트로 (이때 W_j = W_j<<7)
    and  x21, x4, x13      # --- 홀수 비트 검사
    add  x13, x13, x13
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
    and  x21, x4, x13      # --- 다음 짝수 비트 검사 (복제)
    add  x13, x13, x13
    beq  x21, x0, skip_a   # 비트가 0 이면 jal 없이 바로 skip_a
    jal  x0, add_a
    addi x0, x0, 0         # 실행되지 않는 자리 채움 2개: 위 jal/beq 가 이동할 때 잘못 인출되는 명령이
    addi x0, x0, 0         # done 의 lw 가 되지 않게 한다 (메모리 전력 계수기는 인출된 lw/sw 를 접근으로 센다)

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
