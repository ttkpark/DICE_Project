# 프로젝트 1 INT8 선형계층 느린 기준 어셈블리

2026년 10월 7일 기준. 기존 8×8 unsigned GEMM 과제의 개편을 위한 **작은 signed INT8 연산 기준본**. 우선 어셈블리 동작을 확인하는 패키지이며, 최종 프로젝트 명세·합성용 CPU·공식 학생 채점 덱은 별도 구성 대상.

## 계산 범위

입력 8개로 출력 4개를 계산하는 선형계층의 누산 부분 구현.

```text
Y[j] = BIAS[j] + X[0]*W[j][0] + ... + X[7]*W[j][7]
j = 0, 1, 2, 3
```

- X: signed INT8, -128~127
- W: signed INT8, -127~127
- BIAS: signed INT32, 이 기준본의 입력 범위는 -2^30~2^30
- 곱과 누산 결과: INT32. 위 범위에서는 누산 overflow 없음
- 입력과 가중치의 zero-point: 모두 0으로 고정
- W 저장 순서: row-major. 출력 0의 가중치 8개, 출력 1의 가중치 8개 순서
- activation, scale 적용, requantization, 모델 학습·추론 정확도 평가: 범위 밖

AI 선형계층에서 쓰는 정수 내적의 핵심 연산을 가져온 교육용 커널. **완성된 분류기나 LiteRT 호환 연산자 전체 구현은 아님.**

## 느린 구현의 원인

`baseline_int8_fc_slow.s`는 MUL 명령을 사용하지 않고 W의 절댓값만큼 X를 반복하여 더함. W가 음수이면 X의 부호를 반대로 바꾸어 반복 덧셈. W=0이면 반복 본문을 건너뜀.

32개 중간 곱을 SCRATCH에 모두 저장한 다음, 별도 루프에서 다시 읽어 BIAS와 누산. 따라서 직접 곱셈이나 계산·누산 루프 결합으로 개선할 여지가 있음. 의미 없는 NOP, 고정 시간 대기, 정답 lookup은 사용하지 않음.

‘가장 나쁜 PPA’라는 보장은 없음. 알고리즘이 느린 것과 회로의 면적·전력이 큰 것은 서로 다른 문제. 이 기준본은 **실행량과 메모리 접근의 개선 여지가 큰 기준 프로그램**으로 사용.

## 파일 구성

- `baseline_int8_fc_slow.s`: 한글 주석 포함 어셈블리 원본
- `baseline_int8_fc_slow.hex`: IMEM에 넣을 실제 32비트 명령어, 한 줄당 한 word
- `baseline_int8_fc_slow.lst`: 바이트 PC·기계어·어셈블리 대조표
- `cases/demo.json`: 기본 X·W·BIAS·주소 배치·정답
- `cases/*_dmem.hex`: 각각 512-word 초기 DMEM 이미지
- `cases/*_expected.hex`: 각각 4-word 정답 이미지
- `tools/rv32i_assembler.py`: 기존 W07 8명령 어셈블러
- `tools/reference_run.py`: Python 명령어 단위 기능 실행 모델
- `sim/tb_behavior_cpu.sv`: 독립 simulation-only behavioral HDL 실행 모델
- `verify_all.py`: Python 전체 회귀
- `verify_rtl.py`: Icarus 또는 VCS 전체 회귀
- `FUNCTIONAL_VALIDATION.json`, `HDL_VALIDATION.json`: 제공 기준본의 실제 로컬 검증 결과
- `PPA_비교_주의사항_KO.md`: 이후 PPA 평가 시 비교 조건

이 패키지의 실행 모델은 **기준 어셈블리 검증용**. 학생이 작성할 제어유닛이나 연결을 채점하지 않음. 기존 `W07.tar.gz`는 제어유닛 단독 실습이므로, HEX만 넣어서 프로그램을 실행할 수 없음.

## ISA와 주소 규칙

사용 명령은 ADD, SUB, AND, ADDI, LW, SW, BEQ, JAL의 8개. MUL·LUI·LB·BLT·JALR·ECALL과 의사 명령은 사용하지 않음.

- PC는 바이트 주소. 일반 진행은 PC+4
- BEQ와 JAL의 목표 주소는 **현재 PC + 부호 확장 immediate**
- JAL의 link는 PC+4. `jal x0, label`은 link를 버리는 무조건 점프
- x0 쓰기는 무시, 읽기는 항상 0
- 명령어와 데이터 주소는 4바이트 정렬
- IMEM 로드 위치는 PC=0. HEX 파일의 첫 줄이 IMEM[0]

마지막 출력 store 이후 실행별 DONE_TOKEN을 기록. 검증은 **이 store 이벤트까지** 측정하고, 이후 `park` 루프는 실행량에서 제외.

## INT8 저장 규칙

현재 ISA에 LB가 없으므로 INT8 값을 **부호 확장한 32비트 word 하나씩** 저장. 예를 들어 -3은 `fffffffd`, 127은 `0000007f`로 입력. `000000fd`는 이 계약에서 -3이 아니라 +253이므로 잘못된 입력.

따라서 현재 구현은 INT8 데이터 packing으로 DMEM 용량을 4분의 1로 줄인 구현이 아님. 작은 숫자 범위와 저장 크기를 구분할 것.

## Configuration과 메모리

고정 configuration block 주소는 `0x300`, STATUS 주소는 제공 fixture에서 `0x3F0`. 실제 데이터 base와 DONE 주소·token은 configuration에서 읽음.

|바이트 주소|필드|값 또는 의미|
|---|---|---|
|0x300|X_BASE|입력 8-word window의 시작 주소|
|0x304|W_BASE|가중치 32-word window의 시작 주소|
|0x308|BIAS_BASE|bias 4-word 시작 주소|
|0x30C|Y_BASE|출력 4-word 시작 주소|
|0x310|SCRATCH_BASE|중간 곱 32-word 시작 주소|
|0x314|N|8|
|0x318|M|4|
|0x31C|DONE_ADDR|0x3F0|
|0x320|DONE_TOKEN|매 fixture에서 정한 0이 아닌 32비트 값|
|0x324|SIGN_MASK|0x80000000|

제공 fixture는 `0x000`, `0x100`, `0x200`, `0x400`, `0x500` 다섯 window의 역할을 바꾸어 배치. 각 역할의 사용 영역은 겹치지 않음. DMEM은 512개의 32비트 word, 총 2,048 byte. Configuration과 STATUS 영역은 데이터 window와 별도.

이 메모리 계약은 **INT8 개편안의 새 계약**. 과거 GEMM P1-26FW-v1.0 configuration 이미지와 혼용 금지. 이 프로그램은 N=8, M=4의 고정 과제용이며 임의 shape를 보장하지 않음.

## Python으로 기본 예제 실행

Linux 서버에서 ZIP을 올려둔 위치에서 아래 줄을 위에서부터 순서대로 실행. Python 3 외부 패키지 불필요.

```bash
# 배포 ZIP을 해제. 기존에 같은 폴더가 있으면 먼저 별도 위치에 보관
unzip Project1_INT8_Baseline_20261007.zip

# 기준본 폴더로 이동
cd Project1_INT8_Baseline_20261007

# 현재 위치 확인
pwd

# 원본 어셈블리를 실제 기계어로 다시 인코딩
python3 tools/rv32i_assembler.py baseline_int8_fc_slow.s -o baseline_int8_fc_slow.hex --listing baseline_int8_fc_slow.lst

# 기본 입력을 기계어 기능 모델에서 실행
python3 tools/reference_run.py --program baseline_int8_fc_slow.hex --case cases/demo.json

# 제공된 16개 입력과 주소 배치를 전부 검사
python3 verify_all.py
```

기본 예제의 기대 출력:

```text
PASS demo: Y=[6, 4, 10, 90], 명령 수=900, LD=110, ST=37
```

Windows에서는 위 명령의 `python3`를 `python`으로 변경. `verify_all.py`는 소스와 HEX의 일치도 검사하므로, 원본 수정 후에는 먼저 어셈블러 재실행 필요.

## VCS에서 기본 예제 실행

서버의 VCS wrapper가 일반 VCS 옵션을 전달하는 환경 기준. 실제 수업 서버에서는 조교가 아래 명령으로 한 번 확인한 뒤 배포.

```bash
# 로그와 실행 파일을 둘 폴더를 각각 생성
mkdir -p build
mkdir -p logs

# 독립 behavioral 실행 모델 컴파일
vcs -full64 -sverilog -top TB_BEHAVIOR_CPU sim/tb_behavior_cpu.sv -o build/simv -l logs/compile.log

# 기본 IMEM·DMEM·정답을 넣고 실행
./build/simv +PROGRAM=baseline_int8_fc_slow.hex +DATA=cases/demo_dmem.hex +EXPECTED=cases/demo_expected.hex +WORDS=57 -l logs/demo.log

# 실행 결과 로그 확인
cat logs/demo.log
```

기대 PASS 줄은 다음과 같음. simulator가 추가로 출력하는 종료 안내는 다를 수 있음.

```text
PASS RTL_MODEL steps=900 loads=110 stores=37 Y=6,4,10,90
```

전체 VCS 회귀는 먼저 `python3 verify_all.py`, 다음 `python3 verify_rtl.py --backend vcs` 실행. Icarus가 설치되어 있으면 `python3 verify_rtl.py --backend iverilog`로 대체 가능.

**로컬 검증은 Python 기능 모델과 Icarus의 behavioral HDL 모델에서 수행. 수업 서버 VCS 실행·DC 합성·게이트 타이밍·FPGA 동작은 아직 확인하지 않은 범위.**

## 기준 실행량

|입력 사례|실행 명령 수|데이터 load|데이터 store|
|---|---:|---:|---:|
|demo|900|110|37|
|zero_weights|730|110|37|
|max_positive|16,986|110|37|
|negative_extreme|17,018|110|37|

이 고정 소스의 DONE까지 명령 수는 다음과 같음.

```text
730 + 4 * sum(abs(W[j][i])) + 음수 가중치 개수
```

초기 configuration load와 제어 루프 포함, park 제외. Load 110회는 configuration 10 + X/W 64 + SCRATCH 32 + BIAS 4. Store 37회는 SCRATCH 32 + Y 4 + DONE 1. 명령어 fetch는 실행 명령 수와 같음.

테스트벤치의 10ns clock은 기능 시뮬레이션을 위한 임의 주기. 위 수치를 합성으로 확인한 실행시간·전력·면적 값으로 표시하지 않을 것.

## 이후 개선 실험의 후보

- SCRATCH를 거치지 않고 한 출력의 곱과 누산을 같은 루프에서 처리
- 정확한 의미의 표준 MUL을 지원하는 CPU와 프로그램으로 변경
- 루프 전개로 분기 수를 줄이고 ROM 증가량을 함께 비교
- 선택 확장으로 INT8 packing과 load 처리 추가

하나씩 변경하면서 동일 입력·주소 배치·DONE 계약으로 회귀. 빠르게 만들더라도 signed 결과와 완료 순서는 동일하게 유지.

## 참고 자료

Google LiteRT의 양자화 명세는 signed INT8 입력·가중치와 INT32 bias를 규정함. 이 과제는 그 누산 부분을 단순화하며, 일반적인 scale·입력 zero-point 처리·출력 재양자화 전체는 구현하지 않음. [LiteRT 양자화 명세](https://developers.google.com/edge/litert/conversion/tensorflow/quantization/quantization_spec)

RISC-V의 vector dot-product 제안은 INT8 곱과 INT32 누산을 다룸. 이 과제에서 해당 vector 확장을 구현하거나 확정 표준으로 가정하지 않음. [RISC-V dot-product 제안](https://github.com/riscv/riscv-dot-product/blob/main/intro.adoc)

명령어 의미의 기준: [RISC-V RV32I 공식 명세](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html)
