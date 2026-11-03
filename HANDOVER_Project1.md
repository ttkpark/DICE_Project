# EE362 Project 1 (INT8 선형계층) — 인수인계

작성 2026-11-03 박기호. 조원 회의 결과 + 지금까지 확인된 사실을 한 곳에 모은 문서.
근거 문서가 충돌하면 **`Project1_INT8_Starter_20261020/PROJECT_CONTRACT_KO.md`(계약서)** 와 **R1.3a 배포본(`Project_1/Project1_R1p3a/`)** 이 우선.

---

## 0. 요약

| 항목 | 내용 |
|---|---|
| 할 일 | RV32I CPU 위에서 `Y[j] = BIAS[j] + Σᵢ X[i]·W[j][i]` (i=0..7, j=0..3) 를 계산하는 프로그램 + CPU |
| 우리가 바꾸는 것 | **어셈블리(.s) 최적화**, **CPU RTL** (`TOP.v` 연결, `CONTROLLER.v`, 그리고 `CORE.v` 내부 — 파이프라인) |
| 역할 | **박기호: ASM 최적화** / **김대현: CPU PIPELINE** |
| 팀 내부 마감 | **2026-11-10(화)** |
| 공식 마감 | **2026-11-17(화) 09:00** 제출 (e-Campus 파일 업로드), 같은 날 수업시간 발표, 피어리뷰 설문은 그날 23:59 |
| 기준 명세 | Release 1.3a (2026-10-23) |
| 파이프라인 허용 | **허용됨** (팀 확인) |

---

## 1. 회의 메모와 확인 결과

회의에서 나온 걱정 3개에 대해 지금까지 확인한 답.

| 회의 메모 | 확인 결과 |
|---|---|
| ASM 은 py 로 동작 검증 가능 | 맞음. 단 **`verify_all.py` 는 쓰면 안 됨** — 기준본의 실행량(store 37, load 110, step 수 식)을 assert 하므로 최적화 프로그램은 무조건 FAIL. 배포 PPT 17쪽도 "최적화 프로그램의 공식 채점기로 사용 금지". 대신 `tools/reference_run.py` 의 `run()` 으로 정답·쓰기범위·DONE 순서만 보는 검사기를 쓴다 (§6.1). |
| PIPELINE 은 테스트벤치가 있는지 모르겠다 | **파이프라인 전용 TB 는 없다** (e-Campus 공지·R1.3a ZIP 전부 확인). 그런데 필요 없다: `sim/tb_top_demo.v` 는 TOP 포트(`MEMWRITE/ALURESULT/WRITEDATA`)만 보고 DONE store 를 잡으므로 **파이프라인도 그대로 돌아간다.** 실제로 5단 파이프라인으로 공개 16 case × 3 프로그램 48/48 PASS 확인됨 (§5). |
| PPA 를 스스로 검사 못할지도 | **대부분 가능.** cycle 수·메모리 PPA 는 시뮬레이션(`MEMORY_POWER.v`)이 자동 출력. CPU 의 f·면적·전력은 **학교 서버 DC(`dc_shell_queue`)** 로 직접 측정 가능 (W06/W07 실습과 같은 방식). 상대평가 점수(25점)만 다른 팀 값이 필요해서 못 낸다. 조교에게 물어볼 것 2개 있음 (§8). |
| IMEM 을 64 word 이상 쓸 수 있을지 | **쓸 수 있다.** 계약서: IMEM 은 `.hex` 길이에 따라 64/256/512 word 매크로 중 하나로 자동 결정, 1~512 word 허용. 다만 **비용이 붙는다** (§3.3). 64 초과로 갈지는 PPA 산식으로 판단할 문제. |

---

## 2. 계산·메모리 계약 (프로그램이 지켜야 할 것)

### 2.1 데이터

- X: 8개, −128..127 / W: 4행×8열, −127..127 / BIAS: 4개, −2³⁰..2³⁰ / Y: 4개 (INT32)
- 모두 **32비트 부호확장 word** 1개씩 DMEM 에 저장 (INT8 packing 없음).
- W 는 **row-major `W[j][i]`** (출력 j 마다 8개): 주소 = `W_BASE + (8·j + i)·4`. 즉 같은 i 에서 j 가 바뀌면 32바이트 간격 (`lw` 오프셋 0/32/64/96).
  (회의에서 "W: 8x4" 라고 했는데 메모리 배치는 위 식이 정답.)

### 2.2 설정 블록 (DMEM 0x300, **매 실행 읽어야 함**)

| 주소 | 내용 |
|---|---|
| 0x300 | X_BASE |
| 0x304 | W_BASE |
| 0x308 | BIAS_BASE |
| 0x30C | Y_BASE |
| 0x310 | SCRATCH_BASE (32 word 작업공간) |
| 0x314 / 0x318 | N=8 / M=4 |
| 0x31C | DONE_ADDR |
| 0x320 | DONE_TOKEN (case 마다 랜덤) |
| 0x324 | SIGN_MASK = 0x80000000 |

- **X/W/BIAS/Y/SCRATCH 위치는 case 마다 섞인다** (0x000/0x100/0x200/0x400/0x500 중 랜덤). 주소 하드코딩 금지.
- 쓰기 허용 영역: Y 4 word, SCRATCH 32 word, DONE_ADDR. 그 밖에 store 하면 FAIL.
- Y 4개를 다 쓴 다음 **마지막 store 가 `DONE_ADDR ← DONE_TOKEN`**. 이 store 시점까지가 cycle 수.
- 정답 lookup·입력 특화 코드 금지 (PPT 23쪽).

### 2.3 ISA

- 필수 8개: `ADD SUB AND ADDI LW SW BEQ JAL`.
- 선택: Harris 표 B.1 의 RV32I 정수 명령만 (SLLI, BNE, BLT, OR, XOR, LUI, JALR …). **M 확장(MUL 등) 금지**, 의사명령 금지.
- 선택 명령을 쓰면: CPU 에 구현 + 사용 명령 목록 제출 + 명령별 단독 기능시험 제출. 제공 어셈블러·Python 모델은 8개만 지원하므로 도구도 직접 확장해야 함.
- 구현 안 한 명령·금지 인코딩이 들어오면 `ILLEGAL=1`, 상태 변경 없음 (채점기가 주입해서 검사).
- 지금까지 결론: **기본 8개만으로 충분** (선택 명령이 cycle 을 거의 못 줄임, §4.3).

---

## 3. 채점

### 3.1 PASS/FAIL 관문 (하나라도 FAIL → PPA 0점, 공동 최하위)

1. 기능: 공개 16 + **숨김 8** = 24 case 전부 정답·쓰기범위·DONE 순서
2. 제어유닛·TOP 연결: 고정 포트, 명시적 포트 연결, 안전한 불법명령 처리
3. 재현·개선 근거: 깨끗한 폴더에서 재실행 시 같은 결과, 변경 전후 T/A/P
4. 고정 포트·ISA 준수
5. 합성 + 선언 주파수에서 setup/hold STA 통과

공식 testbench 는 비공개·수정 불가. 예약 입력 20개 = 0, 예약 출력 20개 = 미연결.

### 3.2 PPA 25점 (PASS 팀끼리 상대평가)

```
S = 12.5 × min(1, T_best/T)  +  6.25 × min(1, A_best/A)  +  6.25 × min(1, P_best/P)
T = 24 case 평균 DONE cycle / f
A = CPU cell area + IMEM 매크로 면적 + DMEM 50,667.68 µm²
P = CPU 전력(@f) + 메모리 동적 + 메모리 정적
```
성능 : 면적 : 전력 = **2 : 1 : 1**. 발표는 별도 피어리뷰 10점.

### 3.3 메모리 비용 (IMEM 크기 결정에 직접 영향)

| `.hex` word 수 | IMEM 매크로 | IMEM 면적 [µm²] | 접근 에너지 [pJ] | 메모리 정적전력 [mW] |
|---|---|---:|---:|---:|
| 1–64 | 64×32 | 8,713.50 | 2.23 | 1.188 |
| 65–256 | 256×32 | 27,352.30 | 7.00 | 1.560 |
| 257–512 | 512×32 | 50,667.68 | 12.97 | 2.027 |

```
P_mem = f_MHz/1000 × (E_IMEM + 12.97 × (LOAD+STORE)/cycles) + 0.020 × (A_IMEM + 50,667.68)/1000
```
- 64 → 256 으로 가면 면적 **+18,639 µm²**, 정적전력 **+0.37 mW** (f 무관), 동적전력도 증가.
- 판단 기준: 늘어난 코드로 줄인 cycle(T, 배점 12.5)이 A·P 손해(각 6.25)보다 큰가. 아래 실측 예: 192-word 판이 48-word 판보다 cycle 24% 적음. CPU 면적·전력이 서버에서 나와야 최종 결정 가능.

### 3.4 공통 SDC (R1.3a, `Project1_INT8_CPU_ONLY_20261023.sdc`)

- 바꾸는 숫자는 `create_clock -period 4.00` 한 곳뿐 (주기 ns = 1000/f_MHz).
- 고정: uncertainty setup 0.10 / hold 0.05, clock transition 0.08, 입력·출력 delay min=max=**1.00 ns**, input transition 0.10, load 20 fF, max transition 0.25.
- 입력 delay 대상은 `RESERVED_IN*`, 출력은 `all_outputs` → **TOP 기준으로 합성**한다는 뜻.
- RESET: 동기 active-high. 합성 중에는 고정 금지. 합성·link 후 timing report 직전에만 `set_case_analysis 0 [get_ports RESET]`.
- Corner: **SAED32 RVT SS 0.95 V 125 °C** (수업 실습 setup.tcl 의 `tt1p05v25c` 아님).

---

## 4. ASM (박기호 담당) — 현재 상태

### 4.1 기준본 `baseline_int8_fc_slow.s` (57 word)

- 곱셈을 **|W| 번 반복 덧셈**으로 함 → cycle 이 W 크기에 비례.
- 곱 32개를 SCRATCH 에 저장 → 다시 읽어 BIAS 와 누산.
- 공개 16 case 평균 **8,135.7 cycle** (최대 17,018), load+store 합 2,352.

### 4.2 개선 알고리즘 (작성·검증 완료)

```
acc_j ← BIAS[j]                       (j=0..3, 누산기를 BIAS 로 시작)
for i in 0..7:
    x ← X[i];  w_j ← W[j][i]          (lw 5회, W 오프셋 0/32/64/96)
    for k in 0..6:  x 의 bit k 가 1 이면 acc_j += w_j   (and, beq, add×4)
                    w_j += w_j                          (add×4, doubling)
    bit 7 이 1 이면 acc_j −= w_j      (X = −128·x₇ + Σ 2ᵏxₖ, 부호비트는 뺄셈)
Y[j] ← acc_j;  DONE_ADDR ← DONE_TOKEN
```
- X 의 비트 검사 1번을 4개 행이 공유 → (i,j) 쌍당 약 10 cycle. cycle 은 X 의 1-비트 수에만 의존 (W 크기 무관).
- SCRATCH 안 씀. store = Y 4 + DONE 1 = 5회.

| 프로그램 | word (IMEM) | 평균 cycle (단일 사이클) | 식 (`p = Σᵢ popcount(X[i] & 0xFF)`) |
|---|---|---:|---|
| `int8_small` | **48 (64)** | 729.5 | `609 + 4p` |
| `int8_fast` (i 2개씩 펼침, 비트 루프 완전 전개) | 192 (256) | 552.5 | `432 + 4p` |

### 4.3 검토 후 기각한 것

- 선택 명령(SLLI/SRAI/BGE/BNE): doubling·비트검사가 이미 1명령=1cycle 이라 거의 안 줄어듦. BNE 는 루프당 1 cycle(총 4~8). 대신 디코더·검증 부담 증가.
- k 외부 루프 + Horner: W 32개를 레지스터에 못 올림.
- SCRATCH 에 X 배수 표: 표 생성 비용이 이득보다 큼.
- i 4개 펼침: 353 word → 512 매크로.

### 4.4 다음에 할 것 (11/10 까지)

- 64 word 이하 안에서 `int8_small` 개선: 남은 16 word 로 부분 전개 (fast 와 small 차이 177 cycle 의 일부 회수).
- **파이프라인에 맞춘 코드 배치**: 파이프라인에서는 taken 분기마다 2 cycle 손실 (§5.2) → 비트가 0일 때 분기하는 구조가 불리. 분기 방향·배치를 파이프라인 기준으로 다시 짤 것.
- 숨김 case 대비 랜덤 대량 회귀 (§6.1).

---

## 5. CPU PIPELINE (김대현 담당) — 이미 있는 것

> `Project_1/참고/1020_RISC_PIPELINE/` 에 **5단 파이프라인 CORE 가 이미 구현·검증돼 있음**. 처음부터 짜지 말고 이걸 출발점으로 쓰는 걸 권장. 실행법은 그 폴더 `README.md`, 설계 근거는 `SPEC.md`.

### 5.1 TOP.v / CONTROLLER.v (단일 사이클·파이프라인 공통, 완료)

- **TOP.v**: 포트 그대로, TODO 4연결만 — `u_core.INSTR←INSTR`, `u_core.READDATA←readdata`, `u_imem.ADDR←PC`, `u_dmem.MEMWRITE←MEMWRITE`. 예약 출력 0 고정.
- **CONTROLLER.v**: starter 는 case 문 뒤에 출력을 전부 0·`ILLEGAL=1` 로 다시 덮어쓰는 줄이 있어 모든 명령이 불법이 됨 (함정). 이걸 지우고 재작성. 기본값 0, 매칭 실패 시에만 `ILLEGAL=1`, funct3/funct7 까지 검사.

| 명령 | REGWRITE | MEMWRITE | ALUSRC | RESULTSRC | IMMSRC | ALUCTRL | PCSRC |
|---|---|---|---|---|---|---|---|
| ADD | 1 | 0 | 0 | 00 ALU | 00 | 000 add | 0 |
| SUB | 1 | 0 | 0 | 00 | 00 | 001 sub | 0 |
| AND | 1 | 0 | 0 | 00 | 00 | 010 and | 0 |
| ADDI | 1 | 0 | 1 | 00 | 00 I | 000 | 0 |
| LW | 1 | 0 | 1 | 01 MEM | 00 I | 000 | 0 |
| SW | 0 | 1 | 1 | 00 | 01 S | 000 | 0 |
| BEQ | 0 | 0 | 0 | 00 | 10 B | 001 sub | ZERO |
| JAL | 1 | 0 | 0 | 10 PC+4 | 11 J | 000 | 1 |
| 그 외 | 0 | 0 | 0 | 00 | 00 | 000 | 0, **ILLEGAL=1** |

- 검증: `sim/tb_ctrl.v` 34 벡터 (합법 11 + 불법 23: M 확장, 미구현 RV32I, ECALL/EBREAK, FENCE, 0x00000000, 0xFFFFFFFF) → PASS 34/34.

### 5.2 파이프라인 CORE.v 구조 (Harris & Harris 7.5)

| 항목 | 내용 |
|---|---|
| 단계 | IF / ID / EX / MEM / WB |
| 포트 의미 | `PC` = IF fetch 주소. `ALURESULT/WRITEDATA/MEMWRITE` = **EX/MEM 레지스터 출력** → store 신호가 한 cycle 안정, TB 가 그대로 관찰 |
| CONTROLLER | 무수정. ID 에서 디코드, `ZERO` 입력을 `1'b1` 로 묶어 `PCSRC` 를 "분기 또는 점프" 로 사용 |
| 분기 | EX 에서 해결: `PCSrcE = BranchJumpE & (JumpE \| ZeroE)`, `JumpE = (IMMSRC==11)`. taken 이면 IF/ID·ID/EX flush → **2 cycle 손실** |
| 포워딩 | MEM→EX, WB→EX (`Rs≠0 & Rs==Rd & RegWrite`). MEM 에서 오는 값은 JAL 이면 PC+4 |
| stall | lw-use 1 cycle |
| 레지스터 파일 | write-first (WB 가 쓰는 값을 같은 cycle ID 가 읽음) |
| 버블 | IF/ID 에 INSTR=0 → CONTROLLER 가 ILLEGAL 로 디코드해 제어 0 |
| 리셋 | 동기 active-high, 모든 파이프라인 레지스터·rf 0 |
| 추가 FF | 약 +330 개 |

```
lwStall = ResultSrcE[0] & RegWriteE & (RdE != 0) & ((Rs1D == RdE) | (Rs2D == RdE))
StallF = StallD = lwStall      FlushD = PCSrcE      FlushE = lwStall | PCSrcE
```

### 5.3 측정 결과 (로컬 ModelSim, 공개 16 case 평균)

| 프로그램 | 단일 사이클 | 파이프라인 | 파이프라인 식 |
|---|---:|---:|---|
| baseline | 8,135.7 | 12,170.1 | — |
| `int8_small` (48 word) | 729.5 | 929.2 | `869 + 2p` |
| `int8_fast` (192 word) | 552.5 | 636.2 | `576 + 2p` |

- 기능: 48/48 PASS + tb_ctrl 34/34.
- **cycle 은 파이프라인이 더 많다** (taken 분기 flush). 이득은 f 에서 나와야 함: T = cycle/f 이므로 `int8_small` 기준 단일 사이클보다 빠르려면 `f_pipe/f_single > 1.27`, **2배 빠르려면 > 2.55**.
- 파이프라인 쪽 개선 레버: 분기 해결을 앞당기기(ID 단계 비교 등, 대신 주기 증가 위험), 분기 예측, 그리고 ASM 쪽 코드 배치 (§4.4) — **두 사람이 같이 맞춰야 하는 부분.**
- 주의: `MEMORY_POWER.v` 는 IF 단계의 opcode 로 LOAD/STORE 를 세서 stall 재fetch·flush 된 명령까지 포함 (fast 880 → 1,072). 메모리 전력 영향은 100 MHz 에서 +0.003 mW 수준.

### 5.4 다음에 할 것 (11/10 까지)

- 위 CORE 를 리뷰하고 개선안 결정 (분기 비용).
- `syn/` 을 공식 SDC·SS corner·TOP 합성으로 맞춰 서버에서 최대 f 탐색 (§7).
- 단일 사이클 대비 f 비율을 먼저 확인 → 파이프라인 방향 확정.

---

## 6. 검증 방법

### 6.1 ASM — Python (로컬, 도구 무설치)

```bash
python3 tools/rv32i_assembler.py my.s -o my.hex --listing my.lst   # 어셈블 (기본 8명령만 지원)
python3 tools/verify.py my.hex                                    # 16 case: 정답·쓰기범위·입력보존·DONE 순서
```
- `tools/verify.py` 는 박기호가 만든 검사기 (`reference_run.run()` 사용, 실행량 assert 없음). `verify_all.py` 는 쓰지 말 것 (§1).
- **숨김 8 case 대비**: `tools/make_cases.py` 와 같은 범위(X −128..127, W −127..127, BIAS ±2³⁰ 이내)·같은 주소 섞기로 랜덤 case 를 수백 개 만들어 돌린다 (할 일).

### 6.2 RTL — 시뮬레이션

- 로컬: ModelSim ASE (`run.ps1`) — 어셈블 → Python 16 case → tb_ctrl → RTL 3 프로그램×16 case → 요약표.
- 서버: `vcs_queue` (`run.sh [F_MHZ]`). 끝에 `PASS 48/48`, `TB_CTRL PASS=34 FAIL=0` 이어야 함.
- `+F_MHZ=<선언주파수>` 를 주면 `MEMORY_POWER.v` 가 cycle·LOAD·STORE·메모리 면적·전력·T 를 출력.

---

## 7. PPA 측정 (서버)

| 항목 | 방법 | 상태 |
|---|---|---|
| cycle, LOAD/STORE | 시뮬레이션 | ✅ 있음 |
| 메모리 면적·전력 | 산식 (`MEMORY_POWER.v`, `tools/summarize.py`) | ✅ 있음 |
| 최대 f | DC + 공식 SDC, period 를 줄여가며 setup/hold slack ≥ 0 인 최소값 | ⏳ 서버에서 할 일 |
| CPU cell 면적 | DC `report_area` | ⏳ |
| CPU 전력 | DC `report_power` (선언 f, SAIF 활동률) | ⏳ (방식은 조교 확인, §8) |

- 서버 DC 실행: `dc_shell_queue` (W06/W07 실습과 같음), 큐 상태 `synopsys_queue_status`.
- 서버에서 먼저 확인할 것: SS 라이브러리 존재
  `ls /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/ | grep ss0p95v125c`
- 기존 합성 스크립트는 **CORE 대상 + 주기 40% IO delay 를 가정하고 있어서** R1.3a 공식 SDC(1.00 ns 고정, TOP 대상)로 바꿔야 함.
- 상대평가 점수는 다른 팀 값이 필요해 직접 계산 불가. 우리 T/A/P 와 시나리오만 계산.

---

## 8. 조교에게 확인할 것

1. **TOP 합성 시 IMEM/DMEM 을 어떻게 빼는가** (블랙박스? 제거?). 단일 사이클은 PC → IMEM → INSTR 경로가 한 cycle 안이라, 이 처리에 따라 f 가 크게 달라짐 → 단일 사이클 vs 파이프라인 비교 자체가 바뀜.
2. **CPU 전력의 입력 activity 방식** (testbench SAIF 주입? DC 기본값?).
3. (참고) PPT 4쪽의 "합성 CPU·확장 검증기는 별도 배포" 가 아직 남아 있는지. 우리는 기본 8명령만 쓰고 합성 가능한 CORE 가 이미 있어 영향은 작음.

---

## 9. 파일 위치

| 무엇 | 위치 |
|---|---|
| R1.3a 배포본 (SDC, PPT/PDF, 릴리스노트) | 이 레포 `Project_1/Project1_R1p3a/` |
| starter (R1.2 기준, TOP 연결됨·CONTROLLER 미완) | `Project_1/Project1_INT8_Starter_20261020/`, 사본 `Project_1/starter_giho/` |
| 기준본 실습 패키지 (`tb_behavior_cpu.sv`, `verify_rtl.py`) | `Project_1/Project1_INT8_Baseline_20261007/` |
| 단일 사이클 완성본 (TOP/CONTROLLER/ASM 2종/검증·합성 스크립트, 명세 `SPEC.md`) | `Project_1/참고/1020_RISC/` |
| 파이프라인 완성본 (5단 CORE.v, 명세 `SPEC.md`) | `Project_1/참고/1020_RISC_PIPELINE/` |
| 공식 SDC 원문 | `Project_1/Project1_R1p3a/Project1_INT8_CPU_ONLY_20261023.sdc` |

참고: R1.3a ZIP 안의 starter 는 TOP 의 4연결이 `32'b0` TODO 로 비어 있는 버전이다. 레포의 starter 는 TOP 연결이 이미 된 R1.2 사본.

---

## 10. 일정

| 날짜 | 할 일 |
|---|---|
| ~11/10(화) | 박기호: ASM 개선 (64 word 이내 + 파이프라인 맞춤 배치), 랜덤 회귀 / 김대현: 파이프라인 확정, 서버 합성으로 f 확인 |
| 11/10 이후 | 두 결과 합쳐 최종 프로그램·CPU 결정 (§3.2 산식), 조교 답변 반영, 발표자료 |
| **11/17(화) 09:00** | 제출: RTL(TOP/CORE/CONTROLLER + 수정 모듈), `.s/.hex/.lst`, 선택명령 목록·시험(없으면 "없음"), 기능 로그, STA·area·power 보고서, 선언 f, cycle·LOAD/STORE, IMEM 용량, 재현 절차 |
| 11/17 수업 | 발표 (피어리뷰 10점: 설계 설명·기능 증거·T/A/P 비교·개선 근거·재현·질의응답) |
