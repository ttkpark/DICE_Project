# 1020_RISC — Project 1 INT8 선형계층 결정사항·명세서

작성 2026-10-20. 근거 문서는 `디지털집적회로모델링실험/Project1/Project1_INT8_Starter_20261020/PROJECT_CONTRACT_KO.md`(R1.2).
채점 문구가 충돌하면 계약서가 우선이다. 이 문서는 **우리 팀이 무엇을 어떻게 만들기로 했는지**를 고정한다.

## 0. 결론 한눈에

| 지표 (로컬 RTL, 공개 16 case) | 기준본 `baseline_int8_fc_slow` | **`int8_fast` (기본안)** | `int8_small` (대안) |
|---|---:|---:|---:|
| 평균 DONE cycle | 8,135.7 | **552.5** (×14.7) | 729.5 (×11.2) |
| 최대 cycle (max_positive) | 17,018 | 656 | 833 |
| load+store (16 case 합) | 2,352 | 880 | 880 |
| IMEM word 수 → 매크로 | 57 → 64×32 | 192 → 256×32 | 48 → 64×32 |
| 메모리 면적 가산 [µm²] | 59,381 | 78,020 | 59,381 |
| 메모리 전력 @100 MHz [mW] | 1.434 | 2.390 | 1.508 |
| 기능 PASS (Python 모델 / RTL) | 16/16 / 16/16 | 16/16 / 16/16 | 16/16 / 16/16 |

CPU(CORE) 면적·전력·최대 주파수는 서버 DC 합성 뒤에 채운다. 세 프로그램 모두 **같은 CPU**에서 돌린다.

## 1. 결정사항

| # | 결정 | 이유 |
|---|---|---|
| D1 | **단일 사이클 CORE, `CORE.v` 무수정** | 계약은 "선택 명령 구현에 필요한" 내부 변경만 허용. 파이프라인·레지스터파일 개조는 PASS 관문(제어·연결·ISA)에서 해석 분쟁 소지. 기능 FAIL = 0점이므로 가장 안전한 쪽. |
| D2 | **기본 8개 명령만 사용, 선택 RV32I 미구현** | 비트 직렬 곱의 비용은 (a) W doubling 28/i, (b) 비트 검사 16/i 인데 SLLI/SRAI/BGE 를 써도 둘 다 1명령=1cycle 이라 줄지 않는다(§2.3). 선택 명령은 공식 어셈블러·단독시험 제출·채점기 주입 검사가 따라붙고 디코더 면적만 늘린다. |
| D3 | **곱셈 = X 비트 직렬 + W doubling, 부호비트는 뺄셈** | X 한 개의 비트 검사를 4개 행이 공유 → (i,j) 쌍당 ≈10 cycle. 32비트 부호확장 word 라 `X = −128·x₇ + Σ₍ₖ₌₀..₆₎ 2ᵏxₖ` 를 그대로 쓰면 부호 분기 없이 bit 7 만 `sub`. |
| D4 | **곱한 즉시 누산, SCRATCH 미사용, 누산기 = BIAS 초기값** | 기준본의 SCRATCH 저장·재읽기 64회와 bias 합산 루프 제거. store 는 Y 4 + DONE 1 = 5회뿐. |
| D5 | **프로그램 2종 제출 준비: `int8_fast`(기본) / `int8_small`(대안)** | T 배점이 2배라 cycle 24% 적은 fast 가 유리하지만, 256-word IMEM 은 면적 +18.6k µm², 정적전력 +0.37 mW. 최종 선택은 §2.5 산식에 서버 측정값을 넣어 결정. |
| D6 | **선언 주파수 = setup·hold STA 를 모두 통과하는 최대 f** | T∝1/f(배점 12.5), 메모리 정적전력(≈1.2~1.6 mW)은 f 무관, 동적전력만 f 비례(배점 6.25). f 를 올릴수록 S 가 증가. |
| D7 | **합성 대상 = `CORE`(CONTROLLER 포함)** | TOP 은 배선 + 시뮬레이션용 IMEM/DMEM(`$readmemh`)이라 합성 불가. SRAM 비용은 계약 산식으로 가산(`tools/summarize.py`). |
| D8 | **SDC 는 지난 학기 구조(입출력 지연 = 주기 40%)를 변수화해 사용** | 공식 SDC 미배포. `syn/CORE.sdc` 의 `PERIOD`, `IO_FRAC` 만 바꾸면 됨. 조교가 주면 그 파일로 교체. |
| D9 | **testbench 무수정. 검증은 3단** | ① Python ISA 모델 16 case(`tools/verify.py`: 정답·쓰기범위·입력보존·DONE 순서) ② RTL 16 case × 3 프로그램 ③ CONTROLLER 디코드 34 벡터(`sim/tb_ctrl.v`, 불법 23종 → `ILLEGAL=1`, 쓰기 0). |
| D10 | **멀티코어 안 함** | TOP 고정 포트에 단일 포트 IMEM/DMEM 1개씩 → 코어 2개가 메모리를 공유 못 함. 면적 2배에 T 는 최대 1/2 인데 소프트웨어만으로 이미 ×14.7. |

## 2. 명세

### 2.1 계산·메모리 계약 (계약서 요약)

- `Y[j] = BIAS[j] + Σᵢ X[i]·W[j][i]`, i=0..7, j=0..3. X∈[−128,127], W∈[−127,127], 각 값은 32비트 부호확장 word.
- 0x300 설정 블록을 **매 실행 읽는다**: +0 X_BASE, +4 W_BASE, +8 BIAS_BASE, +12 Y_BASE, +16 SCRATCH_BASE, +20 N=8, +24 M=4, +28 DONE_ADDR, +32 DONE_TOKEN, +36 SIGN_MASK.
- 쓰기 허용: Y(4 word), SCRATCH(32 word), DONE_ADDR. Y 4개를 다 쓴 뒤 **마지막 store** 가 DONE_TOKEN.
- W 는 row-major: `W[j][i]` 주소 = `W_BASE + (8j + i)·4` → i 고정 시 j 간격 32바이트 (`lw` 오프셋 0/32/64/96).

### 2.2 하드웨어

**TOP.v** — 포트 선언 그대로, 내부 4연결만 완성: `u_core.INSTR←INSTR`, `u_core.READDATA←readdata`, `u_imem.ADDR←PC`, `u_dmem.MEMWRITE←MEMWRITE`. 예약 출력 20개는 0 고정, 예약 입력은 사용하지 않음.

**CONTROLLER.v** — 진리표 (CORE.v 의 ALU/IMM/RESULT 인코딩과 일치)

| 명령 | opcode | funct3 | funct7 | REGWRITE | MEMWRITE | ALUSRC | RESULTSRC | IMMSRC | ALUCTRL | PCSRC |
|---|---|---|---|---|---|---|---|---|---|---|
| ADD | 0110011 | 000 | 0000000 | 1 | 0 | 0 | 00 ALU | 00 | 000 add | 0 |
| SUB | 0110011 | 000 | 0100000 | 1 | 0 | 0 | 00 | 00 | 001 sub | 0 |
| AND | 0110011 | 111 | 0000000 | 1 | 0 | 0 | 00 | 00 | 010 and | 0 |
| ADDI | 0010011 | 000 | – | 1 | 0 | 1 | 00 | 00 I | 000 | 0 |
| LW | 0000011 | 010 | – | 1 | 0 | 1 | 01 MEM | 00 I | 000 | 0 |
| SW | 0100011 | 010 | – | 0 | 1 | 1 | 00 | 01 S | 000 | 0 |
| BEQ | 1100011 | 000 | – | 0 | 0 | 0 | 00 | 10 B | 001 sub | ZERO |
| JAL | 1101111 | – | – | 1 | 0 | 0 | 10 PC+4 | 11 J | 000 | 1 |
| 그 외 | | | | 0 | 0 | 0 | 00 | 00 | 000 | 0 | **ILLEGAL=1** |

불법 명령: funct3/funct7 까지 검사. `ILLEGAL=1` 이면 CORE 가 레지스터 쓰기를 막고(`REGWRITE && !ILLEGAL`), MEMWRITE=0, PCSRC=0 → PC+4 로 진행, 상태 변경 없음. M 확장(MUL/DIV…), 미구현 선택 RV32I(SLLI, BNE, JALR, LUI, LB, SB…), ECALL/EBREAK, FENCE, 0x00000000, 0xFFFFFFFF 를 `sim/tb_ctrl.v` 로 확인.

**CORE.v / IMEM.v / DMEM.v / sim/** — starter 그대로(바이트 단위 무수정).

### 2.3 소프트웨어 (`sw/int8_fast.s`, `sw/int8_small.s`)

알고리즘 (두 프로그램 공통)

```
acc_j ← BIAS[j]                      (j=0..3)
for i in 0..7:
    x ← X[i];  w_j ← W[j][i]         (lw 5회)
    for k in 0..6:                    bit k 가 1 이면 acc_j += w_j   (and, beq, add×4)
                                      w_j += w_j                    (add×4, k<7)
    bit 7 이 1 이면 acc_j −= w_j      (= −128·W, 부호 비트)
Y[j] ← acc_j; DONE_ADDR ← DONE_TOKEN  (마지막 store)
```

- `int8_fast`: i 루프를 2개씩 펼침(루프 4회), 비트 루프 완전 전개. 192 word. 레지스터: x1 X ptr, x2 W ptr, x3 끝, x4 X, x5~x8 W, x9~x12 acc, x13~x20 마스크 1..128, x21 temp, x22 token, x30 config.
- `int8_small`: 비트 0..6 을 루프(마스크 x13 doubling, 128 과 비교)로 접음. 48 word. 그 외 동일.
- cycle 산식 (RTL 측정과 일치): `fast = 432 + 4·Σᵢ popcount(X[i] & 0xFF)`, `small = 609 + 4·Σᵢ popcount(X[i] & 0xFF)`. 최악(X 전부 −1) fast 688 / small 865, 최선(X 전부 0) 432 / 609.
- 왜 선택 명령이 도움이 안 되는가: (i,j) 쌍당 비용 = W doubling 7 + 비트 검사(and+beq) 2×8/4 + 조건부 add ≤8 ≈ 10~19. SLLI 는 doubling 1명령을 1명령으로 바꿀 뿐이고, BGE 로 부호비트 검사(1명령)를 하려면 X 를 `slli 24` 로 올리고 W 를 `srai` 로 내려야 해 총 명령 수가 같다. BNE 는 루프 1회당 1 cycle(총 4~8) 절약에 그친다.
- 검토 후 기각한 대안: (a) k 외부 루프 + 누산기 Horner — W 32개를 레지스터에 못 올림, 2행씩 나누면 루프 오버헤드로 fast 보다 느림. (b) SCRATCH 에 X 배수 표 — 표 생성 47 cycle/i 로 이득 없음. (c) i 4개 펼침 — 353 word 로 512 구간 진입.

### 2.4 메모리 PPA 가산 (계약 산식, `tools/summarize.py` 가 계산)

```
A_total = A_CPU_cell + A_IMEM(64:8,713.50 / 256:27,352.30 / 512:50,667.68) + 50,667.68
P_mem   = f/1000·(E_IMEM(2.23 / 7.00 / 12.97 pJ) + 12.97·(LD+ST)/cycles) + 0.020·(A_IMEM+50,667.68)/1000
T       = mean(cycles)/f
```

### 2.5 최종 프로그램 선택 규칙 (서버 합성 후)

CPU 면적 `a`[µm²], CPU 평균전력 `p`[mW]@f 를 넣어 두 프로그램의 `S_25` 를 계산한다. 우리 팀이 T_best 이고 A/P 는 small 이 best 라는 가정으로:

| CPU (a, p@100 MHz) | S(fast) | S(small) | 차이 |
|---|---:|---:|---:|
| 5,000 µm², 1 mW | 21.97 | 21.97 | 0 |
| 10,000 µm², 2 mW | 22.42 | 21.97 | +0.45 fast |
| 20,000 µm², 4 mW | 22.95 | 21.97 | +0.98 fast |

→ 기본은 **fast**. 단, 다른 팀의 T_best 가 우리보다 15% 이상 낮으면 T 항 차이가 줄어 small 이 역전할 수 있다(T_best=470 이면 동률). 발표 전 조교 공지의 분반 결과를 보고 산식으로 재확인한다.

## 3. 제출물 매핑 (계약서 "평가와 제출" ↔ 이 폴더)

| 요구 | 파일 |
|---|---|
| TOP/CORE/CONTROLLER RTL | `rtl/TOP.v`, `rtl/CORE.v`, `rtl/CONTROLLER.v` (+ `rtl/IMEM.v`, `rtl/DMEM.v` 무수정) |
| 어셈블리 `.s`, 재생성 `.hex`/`.lst` | `sw/int8_fast.{s,hex,lst}`, `sw/int8_small.*`, 비교용 `sw/baseline_int8_fc_slow.*` |
| 사용 선택 명령 목록·단독시험 | 없음(기본 8개만). 불법 명령 안전 처리 증거: `sim/tb_ctrl.v`, `build/tb_ctrl.log` |
| 기능 로그 | `results/functional_*.json`(Python), `build/sim_*.log`(RTL), `results/cycles.csv` |
| STA·area·power 보고서 | `syn/reports/timing_max.rpt`(setup), `timing_min.rpt`(hold), `area.rpt`, `power.rpt`, `qor.rpt` |
| 선언 주파수, cycle, load/store, IMEM 용량 | `results/cycles.csv` + `summarize.py` 요약표 (F_MHZ 인자) |
| 재현 절차 | `README.md`, `run.sh`(시뮬), `syn/run_synth.sh`(합성) — 깨끗한 폴더에서 zip 풀고 두 줄 |
| 개선 근거(변경 전후 T/A/P) | 같은 CPU 에서 baseline/small/fast 를 한 번에 돌려 비교 (`run.sh` 요약표) |

## 4. 미확정 — 조교·교수님께 확인할 것

1. **공식 SDC** (입출력 지연 비율, 클럭 uncertainty) 와 합성 corner(`setup.tcl` 은 W06 의 tt 1.05 V 25 °C; 계약서 SRAM 기준은 ss 0.95 V 125 °C).
2. 합성 대상이 `CORE` 인지 (IMEM/DMEM 제거한) `TOP` 인지. 전력 activity 를 SAIF 로 주입하는지 DC 기본값인지.
3. 공식 채점기의 cycle 정의가 tb_top_demo 의 `steps`(리셋 해제 후 첫 posedge부터 DONE store posedge까지) 와 같은지.
4. 팀 구성, 마감(Canvas 는 "마감일 없음"), 제출 zip 구조(PDF 24쪽 예시 폴더명을 그대로 쓸지).
5. 멀티코어 문의는 하지 않음(D10). 필요하면 이 문서를 근거로 설명.

## 5. 다음 단계 (서버)

1. `1020_RISC.zip` 업로드 → `unzip` → `bash run.sh 100` : 기능 48회 PASS + tb_ctrl PASS=34 확인.
2. `cd syn && bash run_synth.sh` : `PERIOD` 를 줄여가며 setup/hold slack ≥ 0 인 최소값 탐색 → `F_MHZ = 1000/PERIOD`.
3. `DUMP=1 bash run.sh <F_MHZ>` 로 SAIF 생성 후 합성 재실행 → `power.rpt` 의 CPU 전력.
4. `summarize.py <F_MHZ>` 의 P_mem, T 와 `area.rpt`/`power.rpt` 를 §2.5 산식에 넣어 fast/small 결정.
5. 발표(피어리뷰 10점): 설계 설명(§2.2) · 기능 증거(로그) · T/A/P 비교표 · 코드 변경↔지표 연결(§2.3) · 재현 절차(README) · 한계(§2.5, §4).
