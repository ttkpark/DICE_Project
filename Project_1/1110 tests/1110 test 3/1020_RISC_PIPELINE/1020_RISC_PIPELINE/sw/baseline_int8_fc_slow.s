# EE362 Project 1 제안 기준본: signed INT8 선형계층, INT32 누산
# 작성일: 2026-10-07
# 계산: Y[j] = BIAS[j] + sum(X[i] * W[j][i]), i=0..7, j=0..3
# X 범위 -128..127, W 범위 -127..127, 두 zero-point 모두 0
# 메모리에서는 각 INT8 값을 부호 확장한 32비트 word로 저장.
# INT8 packing, scale 변환, activation, requantization은 여기서 수행하지 않음.
#
# 느린 기준 구현의 원인
# 1. MUL 없이 곱셈을 반복 덧셈으로 수행.
# 2. 32개 중간 곱을 SCRATCH에 저장한 뒤 별도 루프에서 다시 읽어 누산.
# 의미 없는 NOP 지연은 넣지 않음. PPA 최악이라는 측정 주장은 하지 않음.
#
# 고정 configuration 주소: 0x300 = 768
# +0 X_BASE, +4 W_BASE, +8 BIAS_BASE, +12 Y_BASE, +16 SCRATCH_BASE
# +20 N(8), +24 M(4), +28 DONE_ADDR, +32 DONE_TOKEN, +36 SIGN_MASK
# SIGN_MASK=0x80000000. 모든 base와 DONE_TOKEN은 실행마다 읽음.
#
# 레지스터 역할
# x20 config, x21 X base, x22 W 이동 포인터, x23 bias 이동 포인터
# x24 Y 이동 포인터, x25 SCRATCH base, x26 N, x27 M
# x28 DONE 주소, x29 DONE token, x31 sign mask, x30 남은 출력 개수
# x1 X 이동 포인터, x2 남은 입력 개수, x3 SCRATCH 이동 포인터
# x4 X, x5 W, x6 W의 sign bit, x7 반복 횟수, x8 중간 곱
# x9 부호 조정한 X, x10 누산기, x11 SCRATCH에서 읽은 곱

start:
    addi x20, x0, 768      # configuration block의 바이트 주소
    lw   x21, 0(x20)       # X_BASE 읽기
    lw   x22, 4(x20)       # W_BASE 읽기
    lw   x23, 8(x20)       # BIAS_BASE 읽기
    lw   x24, 12(x20)      # Y_BASE 읽기
    lw   x25, 16(x20)      # SCRATCH_BASE 읽기
    lw   x26, 20(x20)      # N=8 읽기
    lw   x27, 24(x20)      # M=4 읽기
    lw   x28, 28(x20)      # 완료 표시를 쓸 주소 읽기
    lw   x29, 32(x20)      # 이번 실행의 완료 token 읽기
    lw   x31, 36(x20)      # 0x80000000 sign mask 읽기
    add  x3, x25, x0       # 중간 곱 저장 포인터 초기화
    add  x30, x27, x0      # 남은 출력 행 수 초기화

product_row:
    add  x1, x21, x0       # 매 행마다 입력 벡터 처음으로 복귀
    add  x2, x26, x0       # 이번 행의 곱 개수 N

product_element:
    lw   x4, 0(x1)         # signed X[i], 이미 32비트로 부호 확장된 값
    lw   x5, 0(x22)        # signed W[j][i]
    and  x6, x5, x31       # W가 음수인지 bit 31로 확인
    beq  x6, x0, nonnegative_weight
    sub  x7, x0, x5        # W가 음수이면 반복 횟수 = -W
    sub  x9, x0, x4        # (-W)회 (-X)를 더하면 X*W
    jal  x0, multiply_setup

nonnegative_weight:
    add  x7, x5, x0        # W가 0 이상이면 반복 횟수 = W
    add  x9, x4, x0        # W회 X를 더함

multiply_setup:
    addi x8, x0, 0         # 중간 곱을 0으로 초기화

multiply_loop:
    beq  x7, x0, multiply_done   # W=0일 때도 바로 종료
    add  x8, x8, x9              # 한 번의 반복 덧셈
    addi x7, x7, -1              # 남은 반복 횟수 감소
    jal  x0, multiply_loop       # 조건 검사를 위해 루프 처음으로 복귀

multiply_done:
    sw   x8, 0(x3)         # 중간 곱을 SCRATCH에 저장
    addi x3, x3, 4         # 다음 32비트 word: 바이트 주소는 +4
    addi x1, x1, 4         # 다음 X 원소
    addi x22, x22, 4       # W는 row-major이므로 다음 가중치로 연속 이동
    addi x2, x2, -1        # 이번 행에 남은 원소 감소
    beq  x2, x0, product_row_done
    jal  x0, product_element

product_row_done:
    addi x30, x30, -1      # 곱 계산을 마친 출력 행 수 반영
    beq  x30, x0, accumulate_setup
    jal  x0, product_row

accumulate_setup:
    add  x3, x25, x0       # 모든 중간 곱을 처음부터 다시 읽음
    add  x30, x27, x0      # 출력 행 수 다시 초기화

accumulate_row:
    lw   x10, 0(x23)       # 누산기의 초기값은 BIAS[j]
    add  x2, x26, x0       # 이번 행에서 더할 중간 곱 개수

accumulate_element:
    lw   x11, 0(x3)        # 앞 단계에서 저장한 곱 다시 읽기
    add  x10, x10, x11     # INT32 누산
    addi x3, x3, 4         # 다음 중간 곱
    addi x2, x2, -1        # 남은 항 개수 감소
    beq  x2, x0, accumulate_row_done
    jal  x0, accumulate_element

accumulate_row_done:
    sw   x10, 0(x24)       # Y[j]를 지정 출력 window에 기록
    addi x23, x23, 4       # 다음 bias
    addi x24, x24, 4       # 다음 출력 위치
    addi x30, x30, -1      # 남은 출력 개수 감소
    beq  x30, x0, done
    jal  x0, accumulate_row

done:
    sw   x29, 0(x28)       # 모든 Y store가 끝난 뒤 이번 실행의 token 기록

park:
    jal  x0, park          # 임의 HALT/ECALL 대신 지원 명령으로 정지 루프
