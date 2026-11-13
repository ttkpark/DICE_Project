# EE362 Project 1 — 발표용 통합 컨텍스트

> **2026-11-14 메모.** 이 문서는 11-12 까지 로컬 `Project_1/발표/` 에서 모은 통합 기록이다. main 이 이 R1.7 작업 폴더 하나로 정리되면서 옛 자료는 커밋 [`ffaa3cd`](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1) 에만 남았기 때문에, 링크는 그 커밋의 GitHub 주소로 바꿨다. 본문의 `Project_1/...` 경로도 그 커밋 기준이다. 현재 작업 위치·최신 측정·제출본은 [`../START_HERE_KO.md`](../START_HERE_KO.md), [`../measurements/R1p7_20261114/`](../measurements/R1p7_20261114/README.md), [`../submission/`](../submission/) 을 본다. R1.7 측정값은 이 문서의 R1.4·R1.6 값과 끝자리까지 같다.


작성 2026-11-11, **2026-11-12 갱신** (v2 서버 측정 결과, R1.5·R1.6 명세 갱신, R1.6 반영 발표 슬라이드). 이 파일 하나로 프로젝트의 무엇·왜·어떻게·얼마나를 설명하고, 모든 숫자를 원본 파일로 따라갈 수 있게 모았다.
**현재 발표본은 `Project1_발표_R1p6.pptx` / `.pdf`** (19장, 생성기 [`build/build_deck_r16.js`](../presentation/build/build_deck.js))이다. **제출본은 [`../제출/Project1_TEAM_ID.zip`](../submission/Project1_TEAM_ID.zip)**. 팀원용 요약·서버 재현 절차는 [PRESENTATION_1110_KO.html](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_1110_KO.html). 발표 지침과 피어리뷰 대응표는 [발표_지침_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EB%B0%9C%ED%91%9C/%EB%B0%9C%ED%91%9C_%EC%A7%80%EC%B9%A8_KO.md). 지난 판 슬라이드는 `이전판/` 에 있다 (§12).

- 링크는 이 폴더(`Project_1/발표/`) 기준 상대 경로다. `1110_compare.tar` 안 파일은 링크가 안 되므로 tar 내부 경로를 코드로 적는다. 꺼내 보려면 `tar xf ../1110_compare.tar 1110_compare/results/summary.md` 처럼 한다.
- **숫자 규칙:** 발표 숫자는 모두 2026-11-10~11 서버에서 R1.4 공통 flow(R1.4 `run_ppa.tcl`)로 잰 **공개 16 case** 값이다(§6). R1.6 Tcl 로 다시 돌린 최종 실행도 같은 값이다(§10-1). 공식 성적은 숨김 8 case 를 더한 24 case 로 따로 나온다. R1.3a 이전 flow 의 숫자와는 섞지 않는다(§9).

---

## 1. 한 장 요약

| 항목 | 내용 |
|---|---|
| 과제 | 곱셈기 없는 RV32I CPU 에서 `Y[j] = BIAS[j] + Σᵢ X[i]·W[j][i]` (i=0..7, j=0..3) 를 계산하는 어셈블리와 CPU 를 만들고 PPA 로 상대평가 |
| 팀 | 박기호 (어셈블리 최적화), 김대현 (CPU 파이프라인) |
| 최종 조합 | **EX 분기 5단 파이프라인 + `int8_fastv2`, 주기 1.62 ns (617.28 MHz)** |
| 결과 | T 1.0210 µs (평균 630.25 cycle), A 100,342.97 µm², P 15.4104 mW, 공개 16/16 PASS, setup +0.0026 / hold +0.1148 ns |
| 기준 대비 | 배포 기준(단일 사이클, 4.00 ns) T 32.54 µs 대비 약 **31.9배** = 프로그램 14.75 × 단일 사이클 주기 1.05 × CPU 구조 2.06. 슬라이드는 같은 3.82 ns 기준본(31.08 µs) 대비 **30.4배**로 말한다 |
| 제출 형식 | 발표 슬라이드 1부(PPTX 또는 PDF) + RTL·어셈블리·도구 출력 + **R1.6 `results/TOP_mapped.ddc` 필수** |
| 마감 | 제출 2026-11-17(화) 09:00 KST, 같은 날 수업 발표, 동료 평가 23:59 |

원본: [PRESENTATION_1110_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_1110_KO.md) §1, [1112 tests 7 tar](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110%20tests/1112%20tests%207/1110_compare) `1110_compare/results/summary.md`.

## 2. 과제 명세 (R1.4, 2026-11-03)

최우선 근거는 [PROJECT_CONTRACT_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/PROJECT_CONTRACT_KO.md), 원문 PDF 는 [docs/Project1_INT8_PPA_Release1p4_KO_20261103.pdf](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/docs/Project1_INT8_PPA_Release1p4_KO_20261103.pdf).

### 2.1 계산과 메모리
- X 8개(−128..127), W 4×8(−127..127, row-major `W[j][i]`, 주소 `W_BASE + (8j+i)·4`), BIAS 4개(INT32), Y 4개(INT32). 모두 32비트 부호확장 word.
- 설정 블록 0x300: X_BASE, W_BASE, BIAS_BASE, Y_BASE, SCRATCH_BASE, N=8, M=4, DONE_ADDR, DONE_TOKEN, SIGN_MASK. **base 들은 case 마다 섞이므로 매번 읽는다.**
- 쓰기 허용: Y 4 word, SCRATCH 32 word, DONE_ADDR. Y 를 다 쓴 뒤 마지막 store 가 `DONE_ADDR ← DONE_TOKEN`. 이 시점까지가 cycle 수.
- 공개 16 case ([cases/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/cases)): demo, large_bias, max_positive, mixed_sign, negative_extreme, random_00~09, zero_weights.

### 2.2 ISA
- 필수 8개: ADD SUB AND ADDI LW SW BEQ JAL. 선택: Harris 표 B.1 RV32I 정수 명령. **M 확장(MUL 등)·의사명령 금지.**
- 미구현·금지 인코딩은 `ILLEGAL=1`, 상태 변경 없음. 우리는 **기본 8개만** 구현·사용했다.

### 2.3 경계와 flow (R1.4 에서 바뀐 것)
- TOP 은 CPU 만: `INSTR`·`READDATA` 32비트 **입력**, IMEM/DMEM 은 `sim/TB_TOP.v` 가 `sim/mem/` 에서 연결. 예약 입력 20개 = 0, 예약 출력 20개 미연결.
- 공통 SDC [synth/common.sdc](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/synth/common.sdc): 바꿀 수 있는 것은 `-period` 숫자 하나. 입력 delay min=max 1.00 ns(INSTR/READDATA/예약 입력), 출력도 1.00 ns.
- 공식 실행: [run_sim.sh](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/run_sim.sh) (VCS, 16 case 기능 + VCD) → [run_ppa.sh](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/run_ppa.sh) (vcd2saif, DC `compile`, STA, SAIF 전력, SRAM 비용). `compile_ultra` 아님.
- RESET 동기 active-high. R1.3a 의 TOP/TB/SDC·옛 VCD/SAIF/보고서 혼용 금지. 변경 이유: [RELEASE_NOTES_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/RELEASE_NOTES_KO.md).
- **R1.5 (2026-11-12, [ZIP](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_R1p5_ISA_Update_20261112.zip))**: 어셈블러·기능 모델이 Harris 표 B.1 허용 명령 37개(BNE 등) 지원. 설계 설명은 12주차 발표 슬라이드 1부(PPTX/PDF)로 내고 서술형 보고서는 없다. 제출 경로 `presentation/project1.pptx`.
- **R1.6 (2026-11-12, ZIP (로컬 전용 파일, git 에 없음), R1.5 포함 누적)**: 새 `synth/run_ppa.tcl` 이 compile 전에 CPU 하위 모듈의 ungroup 을 막고(`set_ungroup false`), compile 직후 `write_file -format ddc -hierarchy` 로 `results/TOP_mapped.ddc` 를 쓰고 `reports/cpu_hierarchy.rpt`(`report_hierarchy`)를 만든다. DDC 가 없거나 비면 중단한다. **DDC 는 제출 필수**이고, 최종 PPA 를 잰 같은 실행의 DDC·측정 결과를 낸다. Tcl 이 바뀌었으므로 최종 HEX 로 sim → PPA 를 다시 돈다:
  `unzip -o ../Project1_R1p6_Update_20261112.zip` → `python3 tools/run_flow.py sim --program <최종.hex>` → `bash run_ppa.sh` → `ls -lh results/TOP_mapped.ddc; cat reports/cpu_hierarchy.rpt`.
  e-Campus 공지 "[Project 1 R1.6] 전체 계층 DDC 제출 및 공통 합성 Tcl 업데이트" 도 발표 슬라이드와 기존 검증 자료를 함께 내라고 한다.

### 2.4 채점
- **관문 (하나라도 FAIL → PPA 0/25):** 24 case 기능, 제어유닛·TOP 연결, 재현·개선 근거, 고정 포트·ISA, 합성 + 선언 주파수 setup/hold.
- **PPA 25점 (PASS 팀끼리 상대평가):** `S = 12.5·min(1,T_best/T) + 6.25·min(1,A_best/A) + 6.25·min(1,P_best/P)` → T 가중치가 A·P 의 2배.
  - `T = 평균 DONE cycle / f`
  - `A = CPU cell + IMEM 매크로 + DMEM 50,667.68 µm²`
  - `P = CPU 전력 + 메모리 동적 + 메모리 정적`
- **메모리 비용** (`.hex` 길이로 IMEM 매크로 결정):

| `.hex` word | IMEM 면적 µm² | IMEM 접근 pJ | 메모리 정적 mW |
|---|---:|---:|---:|
| 1–64 | 8,713.50 | 2.23 | 1.188 |
| 65–256 | 27,352.30 | 7.00 | 1.560 |
| 257–512 | 50,667.68 | 12.97 | 2.027 |

`P_mem_dyn = f_MHz/1000 × (E_IMEM + 12.97 × r_D)`, `r_D = (load+store)/cycle`.

- **발표 피어리뷰 10점 평가 요소** (계약서 원문): ① 고정 인터페이스·제어 흐름 설계 설명, ② Y·DONE 과 검사 범위를 보여주는 기능 증거, ③ 같은 조건에서 기준본과 개선본의 T/A/P 비교, ④ 코드 변경과 지표 변화의 연결, ⑤ 파일·명령·조건을 포함한 재현 절차, ⑥ 한계와 trade-off 질의응답. 슬라이드 대응은 §11.

### 2.5 명세 버전 이력
R1.1 (10-20, 예약 포트·SRAM 비용) → R1.2 (10-20, PPA 25·발표 10) → R1.3 / R1.3a (10-23, I/O 1 ns, 동기 RESET, 고정 숫자 SDC) → R1.4 (11-03, CPU-only 경계, INSTR 입력, 공통 스크립트) → R1.5 (11-12, 명령 37개 도구, 슬라이드 제출) → **R1.6 (11-12, 계층 DDC 제출, 공통 Tcl 갱신)**. 옛 판: [Project1_R1p3a/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/Project1_R1p3a), [Project1_INT8_Starter_20261020/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/Project1_INT8_Starter_20261020), [Project1_INT8_Baseline_20261007/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/Project1_INT8_Baseline_20261007/Project1_INT8_Baseline_20261007).

## 3. 진행 경과

| 날짜 | 일 | 원본 |
|---|---|---|
| 10-07 | 기준 어셈블리 패키지 배포 | [Baseline README](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_Baseline_20261007/Project1_INT8_Baseline_20261007/README_KO.md) |
| 10-20 | starter 배포, 팀 자체 flow 시작 (`참고/1020_RISC`, `1020_RISC_PIPELINE`) | [참고/1020_RISC/SPEC.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/1020_RISC/SPEC.md) |
| 10-23 | R1.3a | [Project1_R1p3a/RELEASE_NOTES_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_R1p3a/RELEASE_NOTES_KO.md) |
| 11-03 | R1.4 배포. 팀 인수인계·역할 분담. `int8_opt64` 완성 | [HANDOVER_Project1.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/HANDOVER_Project1.md), git HEAD `Project_1/starter_giho/ASM_OPT_REPORT_KO.md` |
| 11-09 | R1.4 공식 flow 로 개선 전 EX 2.3 ns / ID 3.0 ns × 3 프로그램 측정 | [EX_ID_PPA_COMPARE_20261109.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/EX_ID_PPA_COMPARE_20261109.md), [PPA_ANALYSIS_20261109.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/PPA_ANALYSIS_20261109.md) |
| 11-10 낮 | 자체 flow 로 주기 탐색 (R1.3a 조건, 참고용) | [1110 tests/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110%20tests) test 1~5 |
| 11-10 밤 | **1110 비교 실험**: 3 CPU × 3 프로그램, 주기 탐색 + 공식 flow (21:45~21:58) | [1110_compare.tar](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110_compare), [터미널 로그](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%206%20last%20terminal%20output.txt) |
| 11-11 | 발표용 정리 | [PRESENTATION_1110_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_1110_KO.md) |
| 11-11 | v2 프로그램 2종 서버 측정 (세 CPU, R1.4 Tcl). 최종 조합이 EX + `int8_fastv2` 로 바뀜 | [1112 tests 7/1110_compare.tar](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110%20tests/1112%20tests%207/1110_compare) |
| 11-12 | R1.5·R1.6 배포. R1.5 슬라이드(18장)와 발표 지침 작성, 이어 R1.6 반영 | [발표_지침_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EB%B0%9C%ED%91%9C/%EB%B0%9C%ED%91%9C_%EC%A7%80%EC%B9%A8_KO.md), `Project1_발표_R1p6.pptx` |

## 4. 프로그램 (어셈블리)

### 4.1 알고리즘: 비트 직렬 곱셈, 네 행 공유
X[i] 의 비트 k 가 1 이면 네 누산기 acc_j 에 `W[j][i]<<k` 를 더한다(비트 7 은 부호 비트라 뺀다). `W<<k` 는 매 비트 `add w,w,w` 로 두 배, 비트 검사는 `and + beq`. **비트 검사 한 번을 출력 4행이 같이 쓴다.** 누산기는 BIAS 로 시작하고 SCRATCH 를 쓰지 않는다 (load 50, store 5).
기준본은 곱을 반복 덧셈으로 만들고 32개 중간 곱을 SCRATCH 에 저장한 뒤 다시 읽어 누산한다 (load 110, store 37).

### 4.2 네 프로그램

| 프로그램 | word | IMEM | 단일 cycle 식 | 평균 cycle 단일 / ID / EX | 원본 |
|---|---:|---:|---|---|---|
| 기준 `baseline_int8_fc_slow` | 57 | 64 | `730 + 4·Σ|W| + (음수 W 수)` | 8135.6875 / 10186.3750 / 12170.0625 (로컬) | [.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/baseline_int8_fc_slow.s) |
| `int8_small` | 48 | 64 | `609 + 4p` | 729.5000 / 831.3750 / 929.2500 | [.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/programs/int8_small.s) |
| `int8_opt64` | 58 | 64 | `554 + 4p + n` | 677.8750 / 751.1250 / 821.3750 | [.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/programs/int8_opt64.s) |
| `int8_fast` | 192 | 256 | `432 + 4p` | 552.5000 / 594.3750 / 636.2500 | [.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/programs/int8_fast.s) |

`p = Σᵢ popcount(X[i] & 0xFF)` (0..64), `n` = 음수 X 개수. 식은 16 case 모두 실측과 일치 (ASM 보고서 §1).

- `int8_opt64` 의 변경 4가지 (ASM 보고서 §2):
  1. 비트 루프 2비트 펼침과 종료 검사 위치 변경 (i 당 분기 13 → 7회)
  2. i 루프 검사를 머리로 옮김 (X≥0 이면 next_i 생략)
  3. 설정 블록을 x0 기준 즉시값으로 읽음
  4. lw 직후 사용 0회 배치 (파이프라인 stall 0)
- 64 word 안에서는 2비트 펼침이 최대(3비트면 69 word). 완전 펼침 하한은 ≈412+4p 이고 353 word 라 512 구간이다. `int8_fast` 는 이 하한과 20 cycle 차이.
- **기각안 8개**: 3비트 펼침, i 2개 동시, 균일 8비트 + 부호 보정, Horner, 분기 없는 비트 검사, Booth, |X| 변환, 16비트 lane packing. 이유는 ASM 보고서 §3 (git HEAD 에만 있음: `git show HEAD:Project_1/starter_giho/ASM_OPT_REPORT_KO.md`).
- **`int8_fast` 를 고른 이유** (EX 기준, `int8_opt64` 대비): A +22.8%, P +30.9% 이지만 T −22.5%. T 배점이 A·P 의 2배라서 fast 를 골랐다.
- **v2** (`int8_opt64v2` 63 word, `int8_fastv2` 193 word): 알고리즘과 명령 종류는 그대로 두고 파이프라인에서 버려지는 cycle 만 줄인 판이다. opt64v2 는 다음 비트가 0 이면 JAL 을 건너뛰고 음수 X 부호 처리 뒤 JAL 을 없앴다. fastv2 는 lw 직후 stall 을 없애고 설정 명령 1개를 줄였다. 평균 cycle 단일 / ID / EX: opt64v2 663.1250 / 721.6250 / 777.1250, fastv2 551.5000 / 592.3750 / 630.2500. **서버 측정 완료(11-11)**, 최종 조합은 fastv2. 소스 tar `1110_compare/<CPU>/programs/`.
- v2 를 고칠 때 피할 함정 두 가지:
  - `sim/MEMORY_POWER.v` 는 IF 에서 인출된 lw/sw 를 접근으로 센다. 그래서 taken 분기·jal 뒤 2 word 에 있는 lw/sw 는 실행되지 않아도 전력에 더해진다.
  - EX 판 `lwStall` 은 opcode 를 보지 않고 rs 자리 비트를 비교해서, lw 다음 명령의 [19:15]·[24:20] 비트가 lw 의 rd 와 같으면 가짜 stall 이 생긴다.

## 5. CPU (세 가지 CORE)

세 실험 폴더는 `rtl/CORE.v` 만 다르다. TOP·[CONTROLLER](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/rtl/CONTROLLER.v)·TB·메모리·SDC·도구·프로그램 HEX 는 같다. 소스는 tar `1110_compare/<CPU>/rtl/CORE.v`.

| | 단일 사이클 | 파이프라인 ID | 파이프라인 EX |
|---|---|---|---|
| 폴더 | `1110_single_cycle` (배포 W08 CORE 무수정, 91줄) | `1110_pipeline_ID` (325줄) | `1110_pipeline_EX` (237줄) |
| 분기 판정 | 같은 cycle | ID 단 | EX 단 |
| taken 분기·JAL 손실 | 0 | 1 cycle | 2 cycle |
| lw 직후 사용 | 0 | 1 cycle stall (BEQ 는 MEM 의 load 도 기다림) | 1 cycle stall |
| 그 밖의 RAW | — | 포워딩 0 cycle | 포워딩 (MEM, WB → EX) 0 cycle |
| 분기 예측 | — | 없음 (항상 PC+4) | 없음 |
| 버블 | — | InstrD=0 → CONTROLLER 가 ILLEGAL 로 디코드, 제어 전부 0 | 같음 |

**넣은 개선 (포트·8명령·동기 RESET 계약과 cycle 수 변화 없음):**

| # | 개선 | 효과 | EX | ID |
|---|---|---|:---:|:---:|
| 1 | BEQ 같음 판정을 뺄셈 결과==0 대신 ALU 와 병렬인 비교기로 | 분기 경로에서 adder 제거 | O | — |
| 2 | 포워딩 select 를 ID 에서 미리 계산해 ID/EX 에 저장 | EX 의 번지 비교기 제거 | O | O |
| 3 | 버블 때 데이터 레지스터는 두고 제어 비트만 0 | flush/stall 팬아웃 축소 (IF/ID 에서 64 FF) | O | O |
| 4 | result mux 를 MEM 단에서 하고 결과 32비트만 MEM/WB 에 저장 | WB 포워딩 경로 mux 제거, FF 66개 감소 | O | O |

로컬 ModelSim 219개 실행에서 개선한 ID 판과 개선 전 ID 판의 cycle 수는 모두 같았다.

**주기를 정하는 경로** (tar `1110_compare/<CPU>/reports/sweep/setup_<주기>.rpt`):

| CPU | 주기 | 가장 느린 경로 | 도착 |
|---|---:|---|---:|
| 단일 | 3.82 ns | `INSTR` 입력 → 레지스터 읽기 → ALU 덧셈기 → `ALURESULT` 출력 (입출력 지연 1.00 ns 씩 포함) | 2.7192 ns |
| ID | 2.36 ns | MEM 결과 → EX 포워딩 → ALU 뺄셈기 → ID 비교기로 포워딩 → 분기 판정 → PC 선택 → `PC` | 2.2077 ns |
| EX | 1.62 ns | `PCE` 레지스터 → 분기 목표 덧셈기 → PC 선택 → `PC` | 1.4653 ns |

## 6. 측정 방법

- 일괄 스크립트 tar `1110_compare/run_all.sh` 가 실험 폴더마다 4단계를 돈다:
  1. 계약 검사 (`tools/check_release.py`)
  2. 주기 탐색 (`tools/sweep_timing.tcl`, 공식 run_ppa.tcl 과 같은 `compile`)
  3. setup·hold 가 모두 0 이상인 최소 주기를 `synth/common.sdc` 에 기록
  4. 프로그램마다 `run_flow.py sim` → `ppa` (= run_sim.sh / run_ppa.sh)
  
  끝나면 `tools/summary.py` 가 `results/summary.md/.csv` 를 만든다.
- 1차 탐색(0.05~0.30 ns 간격)에서 통과한 최소 주기는 3.90 / 2.40 / 1.70 ns 였고, 그 아래를 0.02 ns 간격으로 다시 탐색했다. 1차 주기의 공식 결과는 `comparisons.prev.*/`.
- 고른 주기로 공식 flow 를 돌렸을 때 slack 이 탐색 값과 소수 넷째 자리까지 같았다.
- 주기는 소수 둘째 자리까지 쓴다. TB 시간 단위가 1 fs 라 반주기가 fs 로 나누어떨어져야 공식 flow 의 "cycle × 주기 = 실행 구간" 검사를 통과한다.
- 전력은 배치·배선 전 추정이다. case 별 RTL SAIF 를 같은 합성 결과에 입혀 cycle 가중 평균했다.
- 기준본 조합(단일 + 배포 프로그램)은 서버에서 재지 않았다. 기준 T ≈ 32.54 µs 는 로컬 평균 8135.6875 cycle × 4.00 ns.

## 7. 결과 (공식 flow, 공개 16 case)

### 7.1 PPA 15 조합

아래 9행은 1110 실행(tar `Project_1/1110_compare.tar`), v2 6행은 1112 실행([1112 tests 7 tar](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110%20tests/1112%20tests%207/1110_compare) `1110_compare/results/summary.md`)에서 왔다. 두 실행은 같은 RTL·주기·R1.4 Tcl 이고, 겹치는 fast/opt64 행은 값이 같다. "표 내 점수"는 실행마다 비교한 행 집합이 달라 9행 표 기준으로 두었다 (15행 기준 점수는 [PRESENTATION_1110_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_1110_KO.md) §4).

| CPU | 프로그램 | 주기 ns | f MHz | 평균 cycle | T µs | setup ns | hold ns | A_cpu µm² | A 전체 µm² | P_cpu mW | P_mem 동적 | P_mem 정적 | P 전체 mW | 표 내 점수 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 단일 | int8_fast | 3.82 | 261.78 | 552.5000 | 2.1105 | 0.0008 | 0.1650 | 18152.49 | 96172.47 | 3.2651 | 2.1705 | 1.5604 | 6.9959 | 15.86 |
| 단일 | int8_opt64 | 3.82 | 261.78 | 677.8750 | 2.5895 | 0.0008 | 0.1650 | 18152.49 | 77533.67 | 3.2712 | 0.8592 | 1.1876 | 5.3181 | 17.42 |
| 단일 | int8_small | 3.82 | 261.78 | 729.5000 | 2.7867 | 0.0008 | 0.1650 | 18152.49 | 77533.67 | 3.2472 | 0.8398 | 1.1876 | 5.2745 | 17.12 |
| ID | int8_fast | 2.36 | 423.73 | 594.3750 | 1.4027 | 0.0003 | 0.1030 | 22837.38 | 100857.36 | 6.4392 | 3.5116 | 1.5604 | 11.5112 | 16.85 |
| ID | int8_opt64 | 2.36 | 423.73 | 751.1250 | 1.7727 | 0.0003 | 0.1030 | 22837.38 | 82218.56 | 6.3657 | 1.3793 | 1.1876 | 8.9327 | 16.85 |
| ID | int8_small | 2.36 | 423.73 | 831.3750 | 1.9620 | 0.0003 | 0.1030 | 22837.38 | 82218.56 | 6.3167 | 1.3614 | 1.1876 | 8.8657 | 16.18 |
| EX | int8_fast | 1.62 | 617.28 | 636.2500 | 1.0307 | 0.0026 | 0.1148 | 22322.99 | 100342.97 | 8.8349 | 5.1641 | 1.5604 | 15.5594 | 19.45 |
| EX | int8_opt64 | 1.62 | 617.28 | 821.3750 | 1.3306 | 0.0026 | 0.1148 | 22322.99 | 81704.17 | 8.7022 | 1.9979 | 1.1876 | 11.8878 | 18.39 |
| EX | int8_small | 1.62 | 617.28 | 929.2500 | 1.5054 | 0.0026 | 0.1148 | 22322.99 | 81704.17 | 8.6248 | 1.9883 | 1.1876 | 11.8007 | 17.28 |
| 단일 | int8_fastv2 | 3.82 | 261.78 | 551.5000 | 2.1067 | 0.0008 | 0.1650 | 18152.49 | 96172.47 | 3.2658 | 2.1711 | 1.5604 | 6.9973 | — |
| 단일 | int8_opt64v2 | 3.82 | 261.78 | 663.1250 | 2.5331 | 0.0008 | 0.1650 | 18152.49 | 77533.67 | 3.2579 | 0.8654 | 1.1876 | 5.3109 | — |
| ID | int8_fastv2 | 2.36 | 423.73 | 592.3750 | 1.3980 | 0.0003 | 0.1030 | 22837.38 | 100857.36 | 6.4338 | 3.4764 | 1.5604 | 11.4706 | — |
| ID | int8_opt64v2 | 2.36 | 423.73 | 721.6250 | 1.7030 | 0.0003 | 0.1030 | 22837.38 | 82218.56 | 6.3792 | 1.3714 | 1.1876 | 8.9382 | — |
| **EX** | **int8_fastv2** | **1.62** | **617.28** | **630.2500** | **1.0210** | 0.0026 | 0.1148 | 22322.99 | **100342.97** | 8.8303 | 5.0197 | 1.5604 | **15.4104** | — |
| EX | int8_opt64v2 | 1.62 | 617.28 | 777.1250 | 1.2589 | 0.0026 | 0.1148 | 22322.99 | 81704.17 | 8.7067 | 1.9638 | 1.1876 | 11.8581 | — |

"표 내 점수"는 이 9행끼리만 비교한 값이다. 실제 점수는 다른 팀의 최솟값이 기준이라 **발표에서 점수로 말하지 않는다.**
조합별 근거 파일: tar `1110_compare/<CPU>/comparisons/<프로그램>_P<주기>/ppa_summary.json`, `reports/`, `dc_ppa.log`. EX + fast fingerprint `b7ab054a08c86ab3769dbac1bdf02f6bd14ca707b62cb7cb43250cf12867ddd7`.

### 7.2 주기 탐색 — tar `1110_compare/<CPU>/results/sweep.csv`

| 단일 ns | setup | 통과 | ID ns | setup | 통과 | EX ns | setup | 통과 |
|---:|---:|:---:|---:|---:|:---:|---:|---:|:---:|
| 3.90 | 0.0005 | O | 2.40 | 0.0016 | O | 1.70 | 0.0031 | O |
| 3.88 | 0.0020 | O | 2.38 | 0.0008 | O | 1.68 | 0.0007 | O |
| 3.86 | −0.0020 | X | 2.36 | 0.0003 | **O** | 1.66 | 0.0002 | O |
| 3.84 | −0.0037 | X | 2.34 | −0.0006 | X | 1.64 | −0.0014 | X |
| 3.82 | 0.0008 | **O** | 2.32 | −0.0055 | X | 1.62 | 0.0026 | **O** |
| 3.80 | −0.0000 | X | 2.30 | −0.0019 | X | 1.60 | −0.0000 | X |

hold slack 은 모든 주기에서 0.1030 ns 이상이다. 통과 여부가 주기 순서와 단조롭지 않은 것(EX 1.64 실패, 1.62 통과)은 합성이 목표 주기마다 다른 회로를 만들기 때문이다. 같은 RTL·flow·툴이면 재현된다.

### 7.3 면적·전력 내역
- 면적: CPU cell 단일 18152.49 / ID 22837.38 / EX 22322.99 µm². IMEM 64 = 8713.50, IMEM 256 = 27352.30, DMEM = 50667.68. EX + fast 에서 **메모리가 전체 면적의 77.8%** 라 CPU 구조를 바꿔도 A 는 5% 안에서 움직인다.
- 전력: CPU 전력은 주파수에 비례해서 늘어난다 (fast 기준 단일 3.27 / ID 6.44 / EX 8.83 mW). 메모리 동적 전력도 f 에 비례한다.

### 7.4 개선 전 측정 (1109, 같은 R1.4 flow, 1110 개선 전 RTL, 주기 탐색 전)
[EX_ID_PPA_COMPARE_20261109.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/EX_ID_PPA_COMPARE_20261109.md): EX 2.3 ns + fast T 1.4634 µs, A 101,408.09, P 11.9036 / ID 3.0 ns + fast T 1.7831 µs. 1110 의 1.62 / 2.36 ns 는 RTL 개선과 **주기 탐색 둘 다**의 결과다. 1109 주기는 최소 주기가 아니었으므로 둘의 차이를 RTL 개선 효과로만 말하면 안 된다.

## 8. 기능 검증

| 어디서 | 무엇을 | 결과 |
|---|---|---|
| 서버 공식 flow | 9 조합 각각 공개 16 case | 모두 16/16 PASS, timing PASS |
| 로컬 ModelSim | 프로그램 4종 × 16 case, 실행 도중 RESET 재인가, 해저드 지향 시험(`참고/1020_RISC_PIPELINE/sw/hazard_test.s`), 무작위 프로그램 150개를 ISA 모델과 store 순서·주소·데이터·최종 DMEM 까지 비교 | CPU 마다 219/219 일치 |
| 로컬 ModelSim | 개선한 ID 판 vs 개선 전 ID 판 cycle 수 | 219 실행 모두 같음 |
| Python ISA 모델 | 각 프로그램 16 case + 무작위 회귀(git HEAD `starter_giho/tools/fuzz.py`; `int8_opt64` 단일 사이클 랜덤 5,000 case 에서 572~771 cycle) | PASS |
| 계약 검사 `tools/check_release.py` | TOP 48 포트, 합성 목록(CPU RTL 3개), 공통 SDC | 통과 |

검증 도구 위치: 팀 TB `참고/1020_RISC*/sim/tb_pj1.v` (모든 store 를 trace 로 남겨 ISA 모델과 1:1 비교), `tools/pj1_check.py`.
`verify_all.py` 는 기준본 실행량을 assert 하므로 최적화 프로그램에 쓰면 FAIL 이 난다. 쓰지 않는다.

## 9. 해석과 말할 때 조심할 것

**해석 (`int8_fastv2` 기준, [PRESENTATION_1110_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_1110_KO.md) §6):**
- EX 는 단일보다 cycle 이 14.3% 많지만 주기가 2.36배 짧아서(3.82 → 1.62 ns) T 가 2.06배 짧다.
- ID 는 EX 보다 cycle 이 6.0% 적지만 주기가 45.7% 길어서 T 가 36.9% 길다 (1.3980 대 1.0210 µs). 이유는 ID 의 "ALU → 비교기 → PC" 경로다.
- P 는 EX 가 가장 나쁘다 (단일의 2.20배). 한 번 실행 에너지 P×T 는 단일 14.74 / ID 16.04 / EX 15.73 nJ 로 비슷하다. 채점 항목은 아니다.
- EX 에서 `int8_opt64v2` 대신 `int8_fastv2` 를 쓰면 A +22.8%, P +30.0% 이지만 T −18.9%. T 배점이 2배라 fastv2 를 골랐다. 다만 차이가 좁아서 A·P 가 아주 작은 팀이 있으면 순서가 바뀔 수 있다.
- v2 효과는 분기가 많은 프로그램에서 크다: EX 에서 opt64 → opt64v2 −5.4%, fast → fastv2 −0.9%.

**조심할 것:**
- 숫자는 공개 16 case 기준이다.
- 타이밍 여유가 EX 2.6 ps, 단일 0.8 ps, ID 0.3 ps 뿐이다. RTL 을 한 줄이라도 고치면 주기를 다시 탐색해야 한다. **R1.6 Tcl 도 합성 조건을 바꾸므로 같은 이유로 재확인이 필요하다** (§10-2).
- R1.3a 이전 flow(`compile_ultra`, 옛 SDC, CORE 합성)의 숫자는 이 표와 섞지 않는다. 예: [PRESENTATION_COMPARE_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_COMPARE_KO.md) 의 2.1 ns / 1.7 ns, `1110 tests/` test 1~5, `참고/*/results/`.
- 기준본의 A·P 는 같은 조건으로 재지 않았다. T 만 로컬 cycle 로 계산했다. 슬라이드 8 의 기준본 P 칸은 "서버 측정 예정" 이다.
- 기준본은 느린 **프로그램**이지 가장 느린 **하드웨어**가 아니다 ([PPA_비교_주의사항_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/PPA_%EB%B9%84%EA%B5%90_%EC%A3%BC%EC%9D%98%EC%82%AC%ED%95%AD_KO.md)).
- 메모리 전력은 계약서의 수업용 추정 산식이고, 실측 SRAM 전력이 아니다.

## 10. 남은 일과 불일치 (2026-11-12 기준)

1. **제출 폴더 (로컬 git) 는 아직 옛 상태다.** 로컬 [rtl/CORE.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/rtl/CORE.v) 는 1110 개선 전 ID 판, [synth/common.sdc](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/synth/common.sdc) 는 4.00 ns 다. 실제 최종본은 p1_final_R1p6.zip (로컬 전용 파일, git 에 없음) (입력)과 p1_final_result.tar (로컬 전용 파일, git 에 없음) (결과)에 있다. 제출 ZIP 은 이 둘로 만든다.
2. **R1.6 반영 재실행 — 완료.** 2026-11-12 18:10 서버에서 R1.6 Tcl 로 재실행 완료 (`p1_final_R1p6.zip` 을 푼 폴더, 결과 `p1_final_result.tar` (로컬 전용 파일, git 에 없음)): 16/16 PASS, timing PASS, T 1.021005 µs · A 100342.97 µm² · P 15.4104 mW · setup +0.00261915 / hold +0.114771 ns 로 **R1.4 Tcl 값과 같다**. `results/TOP_mapped.ddc` 416 KB, `reports/cpu_hierarchy.rpt` 에 TOP → CORE → CONTROLLER 와 DesignWare 하위 계층이 남았다. fingerprint `758cb92e2d9e94cbe658735177ead51ddd36a5dfa4dd527220fad259828dbdd6`. 제출 DDC·보고서는 이 실행의 것을 쓴다.
3. 기준본 조합의 서버 PPA (피어리뷰 ③, 관문 "개선 근거"): 설정은 [발표_지침_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EB%B0%9C%ED%91%9C/%EB%B0%9C%ED%91%9C_%EC%A7%80%EC%B9%A8_KO.md) §9. 측정 후 `build_deck_r16.js` 의 `BASE_P` 에 넣는다.
4. 제출 폴더 `tools/run_flow.py`, `check_release.py`, `trim_vcd.py` 가 원본 ZIP 과 한두 줄 다르다 (서버 Python 3.6 호환). R1.6 ZIP 은 이 세 파일을 덮어쓰지 않는다. 질문이 나오면 설명할 수 있게 해 둔다.
5. 발표 시간과 피어리뷰 양식은 자료에 없다. 분반 공지나 조교에게 확인한다.
6. 낡은 문구: tar 안 `1110_compare/README.md` 의 "서버 실행 아직 안 함", HANDOVER 의 "기준 명세 R1.3a".

## 11. 피어리뷰 평가 요소 ↔ 슬라이드

현재 발표본(`Project1_발표_R1p6`, 19장) 기준 대응표는 [발표_지침_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EB%B0%9C%ED%91%9C/%EB%B0%9C%ED%91%9C_%EC%A7%80%EC%B9%A8_KO.md) §3 에 있다. 요약:

| 평가 요소 | R1p6 슬라이드 | 이 문서 |
|---|---|---|
| ① 설계 이해 (인터페이스·제어 흐름) | 4 구조도, 5 제어 흐름 | §2, §5 |
| ② 기능 증거 (Y·DONE, 검사 범위) | 11 서버 로그 + 검사 범위 | §8 |
| ③ 같은 조건 기준본 vs 개선본 T/A/P | 8 기준본 vs 개선본, 9 15개 조합, 부록 A | §1, §4, §7 (기준본 P 미측정, §10-3) |
| ④ 코드 변경 ↔ 지표 변화 | 6 프로그램 변경, 7 경로·RTL 개선, 부록 C | §4, §5, §9 |
| ⑤ 재현 절차 | 12 재현 (R1.6 명령), 부록 B·D, 부록 E (수업 명령만으로) | §2.3, §6, 팀원용 HTML "서버에서 재현" |
| ⑥ 한계·trade-off | 10 트레이드오프, 13 한계와 예상 질문 | §9, §10 |

## 12. 이 폴더 파일과 다시 만드는 법

| 파일 | 무엇 |
|---|---|
| `PROJECT1_CONTEXT_KO.md` | 이 문서 |
| [발표_지침_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EB%B0%9C%ED%91%9C/%EB%B0%9C%ED%91%9C_%EC%A7%80%EC%B9%A8_KO.md) | 수업 자료의 발표·제출 지침 모음 (일정, 배점, 평가 요소, 제출물 구성, 남은 일) |
| **`Project1_발표_R1p6.pptx` / `.pdf`** | **현재 발표본.** 19장 (본문 14 + 부록 A~E), 발표자 노트 포함. R1.5 판에 R1.6 을 반영: 12 재현 명령·최종 fingerprint, 13 한계·예상 질문, 14 정리, 부록 D 실제 제출본 구조, 부록 E 수업 명령만으로 재현 |
| [../제출/](../submission/) | **제출본** `TEAM_ID/` 폴더와 `Project1_TEAM_ID.zip` (97 파일): README, rtl, asm, synth, tools(Python 3.6용), run/reproduce.sh, results(DDC 포함), reports, logs, presentation. `TEAM_ID` 는 팀 번호로 바꿔서 낸다 |
| `이전판/` | 지난 판: `Project1_발표_R1p5.*` (R1.6 반영 전, 11-12 16:01), `Project1_발표.*` (11-11 첫 판, `int8_fast` 9조합) |
| [build/build_deck_r16.js](../presentation/build/build_deck.js) | 현재 발표본 생성기 (pptxgenjs 3.12.0). 맨 위 "수치" 블록만 고치면 된다. `BASE_P` 는 기준본 P 측정 후 채운다 |
| [build/apply_theme.js](../presentation/build/apply_theme.js) | pptxgenjs 가 쓴 pptx 에 테마 색을 넣는 후처리 (생성기 두 번째 인자) |
| [build/export.ps1](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EB%B0%9C%ED%91%9C/build/export.ps1) | pptx → pdf (PowerPoint COM) |
| [build/build_deck.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EB%B0%9C%ED%91%9C/build/build_deck.py) | 11-11 첫 판 생성기 (python-pptx). 지난 판 |

```powershell
# Node.js 와 PowerPoint 가 있는 PC. pptxgenjs 는 한 번만 설치
cd Project_1\발표\build
npm install pptxgenjs@3.12.0
node build_deck_r16.js ..\Project1_발표_R1p6.pptx apply_theme.js
powershell -File export.ps1 -Pptx ..\Project1_발표_R1p6.pptx -Pdf "$((Resolve-Path ..).Path)\Project1_발표_R1p6.pdf"
```

---


## 원본 색인 (2026-11-11 작성, 11-12 보강)

링크는 모두 `Project_1/발표/` 에서 본 상대 경로다. tar 안 파일은 링크할 수 없어서 tar 내부 경로를 코드로 적었다.
수치 유효성 표시:
- **[R1.4]**: 현재 명세(R1.4 공통 flow: TOP 합성, `compile`, `synth/common.sdc`, SAIF 전력)로 낸 수치.
- **[R1.3a 이전]**: CORE 합성, `compile_ultra`, 옛 SDC, 또는 DC 기본 활동률로 낸 수치. R1.4 수치와 같은 표에 섞으면 안 된다.
- **[수치 없음]**: 코드·명세·배포물이라 PPA 수치가 없다.

---

### 0. 레포 루트

GitHub 레포 루트. `HANDOVER` 는 2026-11-03 작성이라 R1.3a 기준이다. 사실 관계는 맞지만 명세 조건은 R1.4로 바꿔 읽어야 한다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [HANDOVER_Project1.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/HANDOVER_Project1.md) | 2026-11-03 팀 인수인계 (박기호): 역할 분담(ASM 박기호 / PIPELINE 김대현), 계산·메모리 계약, 채점 관문, ASM·파이프라인 현황, 조교 질문, 파일 위치, 일정. "기준 명세 R1.3a" 라고 적혀 있다 | 팀의 결정 배경, 제출물 목록(§10), 조교 질문(§8)을 찾을 때. 명세 숫자(SDC, TOP 포트)는 R1.4 문서로 확인할 것 |
| [README.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/README.md) | 두 줄짜리 레포 환영 문구 ("Welcome to cour DICE Project") | 볼 일 없음 |

### 1. `Project_1/` 루트

발표 자료 초안과 압축본이 있다. `PRESENTATION_1110` 만 R1.4 수치를 쓴다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [PRESENTATION_1110_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_1110_KO.md) | **[R1.4]** 1110 비교 실험(단일 사이클 / ID 분기 / EX 분기 × small·opt64·fast) 발표용 정리. 결론은 EX + `int8_fast`, 1.62 ns, T 1.0307 µs, 기준 대비 31.6배. §10 남은 일, §11 원본 위치 | 발표 수치를 옮길 때 가장 먼저 본다. 공개 16 case 수치이고 공식 24 case 성적은 아니다 |
| [PRESENTATION_COMPARE_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_COMPARE_KO.md) | **[R1.3a 이전]** 2026-11-10에 쓴 ASM·SINGLE·PIPELINE 비교. CORE 포트에 SDC를 걸었고 전력은 DC 기본 활동률(SAIF 없음). ZeroE 전 2.1 ns 기준. "팀원 ID 줄인 버전" 칸은 비어 있다 | 개선 이야기(ASM 변경점, 기각안)를 가져올 때만 쓴다. 숫자는 쓰지 않는다. `PRESENTATION_1110` §9 도 섞지 말라고 적어 두었다 |
| [Project1_INT8_Release1p4_20261103.zip](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_Release1p4_20261103.zip) | 2.4 MB. **조교 배포 원본** R1.4 ZIP (83개 파일, 날짜 1980-01-01, LF). 팀 수정이 들어가기 전 상태 | 제출 폴더에서 무엇을 바꿨는지 원본과 비교할 때, 서버에 새로 풀 때 |
| [Project1_R1p5_ISA_Update_20261112.zip](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_R1p5_ISA_Update_20261112.zip) | 16 KB. **R1.5** 업데이트: `PROJECT_CONTRACT_KO.md`, `R1p5_ISA_사용안내_KO.md`, 명령 37개 지원 `tools/rv32i_assembler.py`·`reference_run.py` | 선택 명령 범위, 슬라이드 제출 안내 |
| Project1_R1p6_Update_20261112.zip (로컬 전용 파일, git 에 없음) | 26 KB. **R1.6** 누적 업데이트(R1.5 포함): `RELEASE_NOTES_KO.md`, `README_KO.md`, `PROJECT_CONTRACT_KO.md`, `docs/COMMON_FLOW_KO.md`, `synth/run_ppa.tcl`(CPU 계층 유지 + 계층 DDC + `cpu_hierarchy.rpt`), 도구 2개. 팀 RTL·프로그램·SDC 는 없다 | 제출 전 재실행. **현재 최신 명세** |
| [PRESENTATION_1110_KO.html](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/PRESENTATION_1110_KO.html) | `PRESENTATION_1110_KO.md` 를 보기 좋게 만든 단일 HTML | 브라우저로 볼 때 |
| p1_final_R1p6.zip (로컬 전용 파일, git 에 없음) | 2.4 MB. **최종 제출 폴더 원본**: 공식 R1.4 ZIP + R1.6 ZIP + EX `rtl/` 3개 + `synth/common.sdc`(1.62) + `programs/int8_fastv2.*` + Python 3.6용 도구 3개. 로컬 `check_release.py` 통과 | 서버에서 처음부터 재현할 때 |
| p1_final_result.tar (로컬 전용 파일, git 에 없음) | 6 MB. **[R1.6] 최종 실행 결과** (build/ 제외): `results/ppa_summary.json`, `TOP_mapped.ddc`(제출 필수), `TOP_mapped.v`, `reports/`(setup, hold, area, `cpu_hierarchy.rpt`, case별 power), `logs/` | 제출 ZIP 의 results/reports/logs 원본 |
| [1110_compare.tar](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110_compare) | 107 MB. 2026-11-10 21:58 서버 실행이 끝난 뒤 받아 온 1110 비교 실험 전체(2362개 항목, VCD/SAIF/simv 포함). 내용은 §3 | 서버 원본 보고서(`setup.rpt`, `ppa_summary.json`)가 필요할 때 |

### 2. `Project1_INT8_R1p4_20261103/` — 공식 R1.4 패키지 = 제출 폴더

조교 배포본 R1.4(2026-11-03) 위에 팀 작업(2026-11-09~10)을 얹었다. `run_sim.sh` → `run_ppa.sh` 가 공식 flow다.
**주의:** 지금 `rtl/CORE.v` 는 1110 개선 **전** ID 분기판이고, `synth/common.sdc` 는 4.00 ns 그대로다. 1110 비교 실험의 어느 CORE와도 일치하지 않는다(§11 참고). 원본 ZIP과 비교하면 `rtl/` 세 파일과 `tools/` 세 파일이 다르고, `programs/`, `.bak` 2개, 1109 분석 문서 2개, `.gitignore` 가 추가되어 있다.

**배포 문서 [수치 없음]**

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [README_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/README_KO.md) | 서버 실행 순서(`verify_all.py` → `check_release.py` → `run_sim.sh` → `run_ppa.sh`), 주기 숫자만 바꾸라는 규칙, 폴더 역할 | 서버에서 공식 flow를 돌리기 직전 |
| [RELEASE_NOTES_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/RELEASE_NOTES_KO.md) | R1.3a→R1.4 변경표(CPU-only 경계, INSTR 입력, READDATA 추가, SDC 입력 delay, 공통 스크립트), 이행 절차, 버전 이력 R1.1~R1.4 | "R1.3a 수치를 왜 못 쓰나" 를 설명할 때 |
| [PROJECT_CONTRACT_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/PROJECT_CONTRACT_KO.md) | 평가 계약: 계산식, ISA 범위, 학생 수정 범위, 포트, 메모리 SRAM 비용 산식, PPA 25점 상대평가, 관문 | 채점 규칙·점수 산식·허용 수정 범위를 확인할 때 (최우선 근거) |
| [PPA_비교_주의사항_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/PPA_%EB%B9%84%EA%B5%90_%EC%A3%BC%EC%9D%98%EC%82%AC%ED%95%AD_KO.md) | 기준본은 "느린 프로그램" 일 뿐 최악 하드웨어가 아니라는 설명, 기능 통과 조건, 측정 조건 | 기준 대비 배수를 말할 때 표현을 조심하려고 |
| [MANIFEST.json](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/MANIFEST.json) | 배포 파일 목록과 SHA-256 | 배포본이 원본과 같은지 확인할 때 |
| [RELEASE_VALIDATION.json](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/RELEASE_VALIDATION.json) | 배포자가 로컬에서 한 검사(컴파일, 경계, 비공개 QA 제어기 16 case). 상용 도구 수치 아님 | 배포본 자체의 검증 범위를 물을 때 |
| [FUNCTIONAL_VALIDATION.json](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/FUNCTIONAL_VALIDATION.json) | 기준 어셈블리(57 word)의 Python ISA 회귀 16/16 (명령 900개 등). 학생 CPU PASS 증거 아님 | 기준본 실행량을 인용할 때 |
| [docs/COMMON_FLOW_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/docs/COMMON_FLOW_KO.md) | 공통 flow 단계별 설명(주기 설정, VCS, VCD 자르기, SAIF, DC 명령) | flow 내부에서 무슨 일이 일어나는지 설명할 때 |
| [docs/MEASUREMENT_REVIEW_KO.txt](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/docs/MEASUREMENT_REVIEW_KO.txt) | 조교가 결과를 검토하는 7개 항목(기능, 경계, 환경 SS 0.95V 125°C, timing, activity, power, 재현) | 제출 전 자기 점검 목록 |
| [docs/TOOL_REFERENCE_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/docs/TOOL_REFERENCE_KO.md) | Synopsys Power Compiler 참고 문서 링크 | `read_saif`/`saif_map` 근거가 필요할 때 |
| [docs/TOP_PORT_CONTRACT_R1p4.json](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/docs/TOP_PORT_CONTRACT_R1p4.json) | TOP 48포트 이름·방향·폭 기계 판독용 | 포트 계약 확인 |
| [docs/Project1_INT8_PPA_Release1p4_KO_20261103.pdf](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/docs/Project1_INT8_PPA_Release1p4_KO_20261103.pdf) | R1.4 명세 PDF (29쪽) | 명세 원문 |

**팀 분석 문서 [R1.4, 단 1110 이전 RTL·주기]**

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [EX_ID_PPA_COMPARE_20261109.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/EX_ID_PPA_COMPARE_20261109.md) | 2026-11-09 서버 공식 flow 결과: 개선 전 EX 분기 2.3 ns, ID 분기 3.0 ns × small·opt64·fast 6조합. EX+fast 1.4634 µs. 원본 reports는 로컬에 없고 터미널 요약에서 옮겼다 | 1110 개선 전후 비교(주기 2.3→1.62, 3.0→2.36)를 보여 줄 때. 최종 수치로는 1110 결과를 쓴다 |
| [PPA_ANALYSIS_20261109.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/PPA_ANALYSIS_20261109.md) | 2026-11-09 진행 상황 분석과 다음 실험 제안(EX의 ZeroE 비교기 분리, JAL 비용). 현재 CORE가 ID판, SDC 4.00 이라는 점도 적어 두었다 | 1110 개선을 왜 했는지 설명할 때 |

**프로그램·RTL·시뮬레이션**

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [baseline_int8_fc_slow.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/baseline_int8_fc_slow.s) / `.hex` / `.lst` | 배포 기준 프로그램, 57 word, 반복 덧셈 곱 + SCRATCH 사용, 평균 8135.7 cycle(단일) | 기준 대비 개선을 말할 때 |
| [programs/int8_small.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/programs/int8_small.s) / `.hex` / `.lst` | 팀: 비트 직렬 곱을 비트 루프로 접은 48 word 판 (IMEM 64). `참고/1020_RISC_PIPELINE/sw/` 판과 같다 | 최소 크기 대안 |
| [programs/int8_opt64.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/programs/int8_opt64.s) / `.hex` / `.lst` | 팀(박기호): 2비트 펼침 58 word 판 (IMEM 64). git HEAD `starter_giho/int8_opt64.hex` 와 같다 | 64-word 구간 주력 후보 |
| [programs/int8_fast.s](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/programs/int8_fast.s) / `.hex` / `.lst` | 팀: 비트·i 루프를 펼친 192 word 판 (IMEM 256). `참고/1020_RISC_PIPELINE/sw/` 판과 같다 | 가장 빠른 조합 |
| [rtl/TOP.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/rtl/TOP.v) | R1.4 포트 계약에 맞춘 TOP (CORE만 포함) | 제출 RTL |
| [rtl/CORE.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/rtl/CORE.v) | **현재 활성: 5단 파이프라인 ID 분기판, 1110 개선 전.** `1110_pipeline_ID/rtl/CORE.v` 와 다르다 (diff 140줄) | 제출 전에 1110 판으로 바꿔야 하는지 판단할 때 |
| [rtl/CONTROLLER.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/rtl/CONTROLLER.v) | 팀이 구현한 8명령 제어기. 1110 세 실험과 같다 | 제출 RTL |
| [rtl/CORE_ex_branch.v.bak](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/rtl/CORE_ex_branch.v.bak) / [CORE_single_cycle.v.bak](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/rtl/CORE_single_cycle.v.bak) | 백업: 개선 전 EX 분기판(1109의 2.3 ns 판) / 배포 W08 단일 사이클 CORE(= `1110_single_cycle`) | 옛 판을 되살릴 때만. 합성 목록(`synth/rtl.f`)에는 없다 |
| [sim/TB_TOP.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/sim/TB_TOP.v), [sim/MEMORY_POWER.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/sim/MEMORY_POWER.v), [sim/mem/IMEM.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/sim/mem/IMEM.v), [sim/mem/DMEM.v](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/sim/mem/DMEM.v) | 배포 고정 TB(1 fs 단위), SRAM 비용 추정기, 메모리 모델. 수정 금지 | 메모리 전력이 어떻게 세어지는지 볼 때 (IF에서 인출된 lw/sw도 센다) |
| [synth/common.sdc](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/synth/common.sdc) | 공통 SDC. 바꿀 수 있는 것은 `-period` 숫자 하나. **현재 4.00** | 제출 주기를 설정할 때 |
| [synth/run_ppa.tcl](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/synth/run_ppa.tcl), [library_setup.tcl](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/synth/library_setup.tcl), [rtl.f](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/synth/rtl.f) | 공식 DC 스크립트(`compile`), SAED32 설정, CPU 소스 목록(TOP/CORE/CONTROLLER) | 합성 조건을 설명할 때 |
| [run_sim.sh](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/run_sim.sh) / [run_ppa.sh](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/run_ppa.sh) | `tools/run_flow.py sim` / `ppa` 를 부르는 한 줄 스크립트 | 공식 실행 |
| [tools/run_flow.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/tools/run_flow.py), [check_release.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/tools/check_release.py), [trim_vcd.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/tools/trim_vcd.py) | 공통 flow 구동, 포트·소스·주기 계약 검사, VCD 실행 구간 자르기. **세 파일 모두 원본 ZIP과 한두 줄 다르다** (`is_relative_to`, `write_text(newline=)` 를 서버 Python 3.6에서 도는 구문으로 바꿈). 1110 tar 판과 같다 | 원본을 고쳤다는 지적을 받으면 이 차이를 설명한다 |
| [tools/reference_run.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/tools/reference_run.py), [rv32i_assembler.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/tools/rv32i_assembler.py), [make_cases.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/tools/make_cases.py), [verify_all.py](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/verify_all.py) | ISA 기능 모델, 8명령 어셈블러, case 생성기, 기준본 전용 회귀(최적화 프로그램에 쓰면 FAIL 난다) | 어셈블·Python 검증 |
| [cases/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/cases) `*.json` / `*_dmem.hex` / `*_expected.hex` | 공개 16 case: demo, large_bias, max_positive, mixed_sign, negative_extreme, random_00~09, zero_weights. case마다 입력 json, DMEM 초기값, 기대 Y | case별 결과를 해석할 때 |
| [.gitignore](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_R1p4_20261103/.gitignore), `tools/__pycache__/` | 팀이 추가한 빌드 산출물 제외 목록 / 캐시 | 볼 일 없음 |

### 3. `1110_compare.tar` 내부 — 1110 비교 실험 서버 결과 **[R1.4]**

2026-11-10 20:10에 만들어 서버에서 21:45~21:58에 돌린 R1.4 공통 flow 재측정이다. 세 폴더는 R1.4 패키지 사본이고 `rtl/CORE.v` 와 `synth/common.sdc` 주기만 다르다. 지금 발표 수치는 모두 여기서 나온다. 공개 16 case 결과다.

| tar 내부 경로 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| `1110_compare/README.md` | 세 CORE(단일 / ID / EX)와 넣은 개선(ID에서 포워딩 select 미리 계산, 버블 때 제어 비트만 0, result mux를 MEM으로, EX는 ZeroE 병렬 비교기 추가) 설명, 실행법 | 실험 설계를 설명할 때. "서버 실행은 아직 안 했다" 는 문장은 실행 전에 쓴 것이라 낡았다 |
| `1110_compare/results/summary.md` / `summary.csv` | 9조합 PPA 표(주기, cycle, T, slack, 면적, 전력, 표 안 상대점수)와 CPU별 주기 탐색 표 | 발표 PPA 표의 원본 |
| `1110_compare/run_all.sh` / `run_all.log` | 일괄 실행 스크립트(계약 검사 → 주기 탐색 → 주기 선택 → 공식 측정 → 요약)와 그 전체 로그 | 재현 절차를 보여 줄 때 |
| `1110_compare/tools/sweep_timing.tcl` / `summary.py` | 후보 주기 합성·STA 반복(공식과 같은 `compile`) / 결과 표 생성 | 주기를 어떻게 골랐는지 설명할 때 |
| `1110_compare/1110_single_cycle/` | 배포 단일 사이클 CORE. 선택 주기 3.82 ns | 단일 사이클 기준점 |
| `1110_compare/1110_pipeline_ID/` | 개선한 ID 분기 5단 파이프라인. 2.36 ns | ID판 수치 |
| `1110_compare/1110_pipeline_EX/` | 개선한 EX 분기 5단 파이프라인. 1.62 ns. **최종 후보** | 제출 RTL로 옮길 원본(`rtl/CORE.v`, `synth/common.sdc`) |
| `1110_compare/<CPU>/comparisons/<프로그램>_P<주기>/` | 조합별 공식 결과: `ppa_summary.json`, `ppa_status.json`, `simulation_manifest.json`, `dc_ppa.log`, `reports/`(setup/hold/area/check, case별 power·annotation) | 숫자의 근거 파일. EX+fast fingerprint `b7ab054a…ddd7` |
| `1110_compare/<CPU>/comparisons.prev.<시각>/` | 1차 주기(3.90 / 2.40 / 1.70 ns)의 공식 결과 | 주기를 줄이기 전 값과 비교할 때 |
| `1110_compare/<CPU>/results/sweep.csv`, `reports/sweep/setup_<주기>.rpt` | 주기 탐색 표와 주기별 경로 보고서 | 임계 경로 설명 |
| `1110_compare/<CPU>/results/`, `reports/`, `logs/` | 마지막으로 돈 프로그램의 공식 결과·VCS/vcd2saif/DC 로그 | 로그 확인 |
| `1110_compare/<CPU>/programs/int8_opt64v2.s`, `int8_fastv2.s` (+`.hex`/`.lst`) | 파이프라인 손실 cycle을 줄인 v2 프로그램(63 / 193 word). 로컬 ModelSim과 Python만 확인, **서버 공식 flow 미측정**. `run_all.sh` 의 PROGRAMS 에 들어 있지 않다 | v2를 재측정할 때. 아직 발표 수치로 쓰지 않는다 |
| `1110_compare/<CPU>/` 나머지 | R1.4 패키지 사본(docs, cases, sim, tools 등) + `default.svf`, `ucli.key`, `command.log` 산출물 | 볼 일 없음 |

### 4. `1110 tests/` — 2026-11-10 서버 실행 기록

번호 순서대로 그날 서버에서 돌린 결과를 받아 둔 것이다. **test 1~5 는 `참고/1020_RISC*` 의 자체 flow가 R1.4로 옮겨지기 전 판이다**(CORE 합성, CORE.sdc, `compile_ultra`). 그래서 수치는 [R1.3a 이전]이다. test 6 만 R1.4 공통 flow다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [1110 test 1/1020_RISC.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%201/1020_RISC.tar), [1020_RISC_PIPELINE.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%201/1020_RISC_PIPELINE.tar) | 11:12, 13 / 17 MB. 단일 사이클(주기 P3~P5) · 파이프라인(P2.5~P5) 기능 + DC 합성 결과 (`syn/reports/P*/qor.rpt`, `timing_max.rpt`, `results/cycles.csv`) | R1.3a 조건 주기 탐색 이력이 필요할 때만 |
| [1110 test 2/1020_RISC.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%202/1020_RISC.tar), [1020_RISC_PIPELINE.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%202/1020_RISC_PIPELINE.tar) | 11:34, 15 / 22 MB. 파이프라인 주기를 P2.2~P3.8 로 더 촘촘히 | 같음 |
| [1110 test 3/1020_RISC_PIPELINE.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%203/1020_RISC_PIPELINE.tar) + 풀어 둔 [1020_RISC_PIPELINE/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110%20tests/1110%20test%203/1020_RISC_PIPELINE/1020_RISC_PIPELINE) | 11:52, 26 MB. 파이프라인 P1.8~P2.1 추가. 풀린 폴더에 `run.sh.log`, `run100.log`, `syn/dc_P*.log` | "파이프라인 2.1 ns" (R1.3a) 수치의 출처 |
| [1110 test 4/1020_RISC.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%204/1020_RISC.tar), [1020_RISC_PIPELINE.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%204/1020_RISC_PIPELINE.tar), [1020_RISC_PIPELINE_ZEROE.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%204/1020_RISC_PIPELINE_ZEROE.tar) | 12:43 / 13:22. 앞 결과 갱신본 + ZeroE 수정 파이프라인(P1.6~P2.1) | `PRESENTATION_COMPARE` §3.3 ZeroE(1.7 ns, R1.3a) 수치의 출처 |
| [1110 test 5/TOP_synth_patch.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%205/TOP_synth_patch.tar) | 13:11, 50 KB. 두 폴더의 `syn/synth.tcl`, `run_synth.sh`, `TOP.sdc`, `tools/pj1_check.py` 패치. `DESIGN=CORE|TOP` 선택을 넣었지만 아직 R1.3a SDC와 `compile_ultra` | TOP 합성 이행 과정을 볼 때만 |
| [1110 test 5/1020_RISC_PIPELINE_2.tar](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%205/1020_RISC_PIPELINE_2.tar) | 13:51, 350 KB. 소스만 있는 파이프라인 사본(`rtl/` 에 IMEM/DMEM이 있는 옛 구조) + `int8_opt64` 기능 결과 | 볼 일 거의 없음 |
| [1110 test 6/1110_compare.zip](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%206/1110_compare.zip) | 20:10, 7.5 MB, 330 파일. 서버에 올린 **실행 전** 1110_compare (결과 없음). 결과가 들어 있는 판은 `Project_1/1110_compare.tar` | 올린 입력 그대로를 확인할 때 |
| [1112 tests 7/1110_compare.tar](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110%20tests/1112%20tests%207/1110_compare) (+ 풀어 둔 [1110_compare/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/1110%20tests/1112%20tests%207/1110_compare)) | 128 MB. **[R1.4]** v2 를 넣은 재실행: 세 CPU × fast·fastv2·opt64·opt64v2 12조합 (`results/summary.md`). fast·opt64 값은 1110 실행과 같다 | v2 수치(최종 조합 EX + fastv2)의 원본 |
| [1110 test 6 last terminal output.txt](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/1110%20tests/1110%20test%206%20last%20terminal%20output.txt) | 150 KB. `bash run_all.sh` 터미널 출력 전문 (21:45 시작, 세 실험 PASS) = tar 안 `run_all.log` | tar를 풀지 않고 로그를 볼 때 |

### 5. `참고/1020_RISC/`, `참고/1020_RISC_PIPELINE/` — 팀 자체 탐색 flow

2026-10-20 시작, 2026-11-10에 R1.4 경계로 옮겼다(작업 트리에서 수정됨, 커밋 안 됨): TOP 합성, `syn/TOP.sdc` = R1.4 common.sdc, 기본 `compile`, `rtl/IMEM·DMEM.v` → `sim/mem/`. SPEC 본문, 들어 있는 `results/`, 압축본(11-04)은 **[R1.3a 이전]** 기록이다. 공식 PPA는 이 flow로 내지 않는다. 두 폴더는 `rtl/CORE.v` 와 `sw/*.s` 종료부만 다르다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [1020_RISC/README.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/1020_RISC/README.md), [1020_RISC_PIPELINE/README.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/1020_RISC_PIPELINE/README.md) | 폴더 구조와 실행법(로컬 `run.ps1` ModelSim, 서버 `run.sh` VCS+DC). 경로가 옛 `class-2026-2\` 로 적혀 있다 | 로컬 회귀를 돌릴 때 |
| [1020_RISC/SPEC.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/1020_RISC/SPEC.md) (+[SPEC.html](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/1020_RISC/SPEC.html)), [1020_RISC_PIPELINE/SPEC.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/1020_RISC_PIPELINE/SPEC.md) | 팀 결정사항 D1~D10(기본 8명령, 비트 직렬 곱, 프로그램 2종, 검증 3단)과 파이프라인 구조. 맨 위에 "본문은 R1.3a 시점" 이라는 R1.4 경고가 있다 | 설계 결정의 근거를 발표할 때 |
| `rtl/TOP.v`, `rtl/CONTROLLER.v`, `rtl/CORE.v` | 단일 사이클 CORE(배포본 그대로) / 5단 파이프라인 CORE(EX 분기, 1110 개선 전) | 옛 RTL과 비교할 때 |
| `sw/int8_fast.s`, `sw/int8_small.s`, `sw/baseline_int8_fc_slow.s`, `sw/hazard_test.s` (+`.hex`/`.lst`) | 프로그램. R1.4 제출 폴더의 small/fast는 **PIPELINE 쪽** 판이다(`1020_RISC/sw/` 판은 종료부 load 배치가 다르다). `hazard_test` 는 해저드 지향 시험 | 프로그램 출처를 확인할 때 |
| `sim/tb_pj1.v`, `tb_top_demo.v`, `tb_ctrl.v`, `DUMP_CORE.v`, `MEMORY_POWER.v`, `sim/mem/` | 팀 TB(모든 store를 trace로 남겨 ISA 모델과 1:1 비교), 데모 TB, 제어기 self-check, VCD 덤프 | 기능 검증 방법(219/219)을 설명할 때 |
| `tools/pj1_check.py`, `verify.py`, `summarize.py`, `reference_run.py`, `rv32i_assembler.py`, `make_cases.py` | trace vs ISA 모델 비교·해저드 cycle 분해·PPA 표 / 아무 프로그램에나 쓰는 16 case 검사 / cycles.csv 생성 | 검증 도구 설명 |
| `syn/synth.tcl`, `run_synth.sh`, `setup.tcl`, `TOP.sdc`, `CORE.sdc`, `Project1_INT8_CPU_ONLY_20261023.sdc`, `Project1_INT8_SDC_적용안내_20261023.md` | 자체 DC flow(기본 TOP + `compile`, CORE + `compile_ultra` 는 비공식 비교용). CORE.sdc와 R1.3a SDC 사본도 남아 있다 | 빠른 주기 탐색. 결과는 공식 flow로 다시 잰다 |
| `results/cycles.csv`, `functional_*.json`, `pj1_summary.json` | 로컬 cycle 표(100 MHz 가정, `syn: null`). 파이프라인 `stores` 열은 IF 인출 기준이라 커 보인다(기준본 113 vs 단일 37) | cycle 수 인용. f·A·P 는 쓰지 않는다 |
| `cases/` | 공개 16 case 사본 (R1.4와 같다) | — |
| `run.ps1`, `run.sh`, `make_pkg.py`, `1020_RISC.zip`/`.tar.gz`, `1020_RISC_PIPELINE.zip`/`.tar.gz` | 로컬·서버 실행 스크립트, 업로드 패키지 생성기, **11-04에 만든 R1.4 이식 전** 압축본 | 압축본은 낡았다. 다시 올리려면 `make_pkg.py` 로 새로 만든다 |
| `build/`, `tools/__pycache__/` | 로컬 실행 산출물(`pj1_*.log/.mem/.trc`) | 볼 일 없음 |

### 6. `참고/DICE_실습/` — 주차별 수업 실습 자료 [수치 없음]

수업 배포 실습 W03~W10. Project 1 수치와는 관계없다. 서버 도구(VCS, DC) 사용법을 볼 때만 쓴다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [W03/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W03), [W03_HEX_DEMO/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W03_HEX_DEMO), [dice/W03/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/dice/W03) | W03 조합회로(mux, decoder), DE2/DE2-115 FPGA 7-seg 데모, 예비보고서 예시 | — |
| [W04/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W04), [W04_ALU_DEMO/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W04_ALU_DEMO) | 32비트 조합 ALU (TODO 12곳, 34개 검사) | — |
| [W05/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W05) | 순차논리와 PC (`.README.md.swp` vim 잔재 있음) | — |
| [W06/W06/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W06/W06) | 레지스터 파일 + 첫 DC 합성 (`DC_STEP_BY_STEP_KO.md`, `SERVER_DEPLOY_KO.txt`) | DC 사용법 |
| [W07/W07/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W07/W07) | 제어기(CONTROLLER) + setup/hold 관찰 | CONTROLLER 원형 |
| [W10/DE2/](https://github.com/ttkpark/DICE_Project/tree/ffaa3cd/Project_1/%EC%B0%B8%EA%B3%A0/DICE_%EC%8B%A4%EC%8A%B5/W10/DE2) | DE2 LED 점멸 pre-lab | — |

### 7. `Project1_R1p3a/` — R1.3a 배포본 (2026-10-23) **[R1.3a 이전]**

현재 명세가 아니다. R1.4가 대체했다. 파일 이름은 ZIP을 풀 때 한글이 깨졌다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [RELEASE_NOTES_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_R1p3a/RELEASE_NOTES_KO.md) | R1.3/R1.3a 변경(고정 숫자 SDC, I/O delay 1.00 ns, 동기 active-high RESET, compile 후 case analysis) | 버전 이력 설명 |
| [Project1_INT8_CPU_ONLY_20261023.sdc](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_R1p3a/Project1_INT8_CPU_ONLY_20261023.sdc) | R1.3a SDC. 입력 delay 대상이 `RESERVED_IN*` 뿐이다(R1.4는 INSTR/READDATA 포함) | R1.3a와 R1.4 SDC 차이를 보여 줄 때 |
| [Project1_INT8_SDC_ýáüýܮýòêÙé¦_20261023.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_R1p3a/Project1_INT8_SDC_%C3%BD%C3%A1%C3%BC%C3%BD%DC%AE%C3%BD%C3%B2%C3%AA%C3%99%C3%A9%C2%A6_20261023.md) | 원래 이름 "SDC_적용안내". SDC 값 표와 적용 순서 | 같음 |
| [Project1_INT8_PPA_Ýö+ýû¦٪¼ÙÀ¦_Release1p3_KO_20261023.pdf](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_R1p3a/Project1_INT8_PPA_%C3%9D%C3%B6%2B%C3%BD%C3%BB%C2%A6%D9%AA%C2%BC%C3%99%C3%80%C2%A6_Release1p3_KO_20261023.pdf) / `.pptx` | 원래 이름 "PPA_피어리뷰". R1.3 명세 발표자료 | 옛 명세 |
| `~$Project1_INT8_PPA_…pptx` | PowerPoint 잠금 임시 파일(git에 커밋됨) | 지워도 되는 잔재 |

### 8. `Project1_INT8_Starter_20261020/` — starter (R1.1~R1.2) **[R1.3a 이전]**

2026-10-20 배포 starter. README는 "Release 1.1", 계약서는 "Release 1.2" 로 적혀 있다. TOP에 INSTR 출력, `rtl/` 안에 IMEM/DMEM이 있는 옛 경계다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [README_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_Starter_20261020/README_KO.md) | starter 구성, 고정 TOP 포트·예약 포트 설명 | 옛 경계와 비교할 때 |
| [PROJECT_CONTRACT_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_Starter_20261020/PROJECT_CONTRACT_KO.md) | R1.2 계약서 (HANDOVER가 근거로 삼은 판) | R1.4 계약서와 차이를 확인할 때 |
| [PPA_٦äÛÁÉ_ýú+ýØýé¼Ýò¡_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_Starter_20261020/PPA_%D9%A6%C3%A4%C3%9B%C3%81%C3%89_%C3%BD%C3%BA%2B%C3%BD%C3%98%C3%BD%C3%A9%C2%BC%C3%9D%C3%B2%C2%A1_KO.md) | 원래 이름 "PPA_비교_주의사항" (이름 깨짐) | — |
| `rtl/TOP.v`, `CORE.v`, `CONTROLLER.v`, `IMEM.v`, `DMEM.v`, `sim/tb_top_demo.v`, `sim/MEMORY_POWER.v` | TOP 4연결 TODO, W08 단일 사이클 CORE, 빈 제어기, 메모리 모델, 데모 TB | — |
| `baseline_int8_fc_slow.*`, `cases/`(공개 16 case), `tools/`, `verify_all.py`, `FUNCTIONAL_VALIDATION.json` | R1.4와 같은 기준 프로그램·case·도구 | — |

### 9. `Project1_INT8_Baseline_20261007/Project1_INT8_Baseline_20261007/` — 기준 어셈블리 패키지 (2026-10-07) **[수치 없음]**

폴더가 두 번 겹쳐 있다. 명세가 나오기 전 "느린 기준 어셈블리" 를 확인하는 패키지다.

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| [README_KO.md](https://github.com/ttkpark/DICE_Project/blob/ffaa3cd/Project_1/Project1_INT8_Baseline_20261007/Project1_INT8_Baseline_20261007/README_KO.md) | 계산 범위, 값 범위(X −128~127, W −127~127), 기준본 설명 | 기준본의 원래 의도 |
| `sim/tb_behavior_cpu.sv`, `verify_rtl.py`, `HDL_VALIDATION.json` | simulation 전용 behavioral CPU(합성용 아님)와 Icarus/VCS 회귀 결과 16/16 | — |
| `baseline_int8_fc_slow.*`, `cases/`, `tools/`, `verify_all.py`, `FUNCTIONAL_VALIDATION.json`, `MANIFEST.json`, `PPA_비교_주의사항_KO.md` | 기준 프로그램, 공개 16 case, 도구, 회귀 결과 | — |

### 10. git HEAD 에만 있음 — `Project_1/starter_giho/`

박기호 ASM 작업 폴더(커밋 `42a6c4a ASM 최적화 완료`). 작업 트리에서는 지워졌고 결과 프로그램은 제출 폴더 `programs/int8_opt64.*` 로 옮겨졌다(hex 동일). 모두 git HEAD 에만 있음 (`git show HEAD:<path>`).

| 파일 | 무엇 | 언제 봐야 하나 |
|---|---|---|
| `Project_1/starter_giho/ASM_OPT_REPORT_KO.md` | 2026-11-03 ASM 최적화 보고서(106줄). 4개 프로그램 cycle 식(`opt64 = 554 + 4p + n`), 변경 4가지(2비트 펼침, i 루프 검사 위치, x0 기준 config load, lw-use 0회), 하한 분석(≈412+4p), 기각안 8개, 64 vs 256 word 선택, 검증·재현, 파이프라인 담당에게 주는 메모 | ASM 개선 근거와 기각안을 발표할 때. `PRESENTATION_COMPARE` §2 의 원본 |
| `Project_1/starter_giho/int8_opt64.s` / `.hex` / `.lst` | `int8_opt64` 원본 (= 제출 폴더 `programs/int8_opt64.*`) | — |
| `Project_1/starter_giho/results/functional_int8_opt64.json` | opt64 Python 16/16, 평균 677.875 cycle | — |
| `Project_1/starter_giho/tools/verify.py`, `tools/fuzz.py` | 어떤 프로그램에나 쓰는 16 case 검사 / 숨김 case 대비 무작위 회귀(Y, 쓰기 범위, 입력 보존, DONE 순서) | 랜덤 회귀 방법을 설명할 때 |
| `Project_1/starter_giho/` 나머지 (`rtl/`, `sim/`, `cases/`, `tools/` 기타, `README_KO.md`, `PROJECT_CONTRACT_KO.md`, `PPA_…_KO.md`, `baseline_*`, `verify_all.py`, `__pycache__`) | starter R1.1/R1.2 사본 | 볼 일 없음 |

같은 HEAD 기준으로 `참고/1020_RISC*/rtl/IMEM.v`, `DMEM.v` 도 작업 트리에서 지워졌다(R1.4 이식 때 `sim/mem/` 으로 옮김).

### 11. 서로 안 맞거나 낡은 곳

| 무엇 | 내용 |
|---|---|
| 제출 폴더 RTL | `Project1_INT8_R1p4_20261103/rtl/CORE.v` 는 1110 개선 전 ID판, `synth/common.sdc` 는 4.00 ns. 발표 결론(EX 1.62 ns)과 다르다. 제출하려면 tar 안 `1110_compare/1110_pipeline_EX/rtl/CORE.v` 와 `synth/common.sdc` 를 옮기고 공식 flow를 다시 돌려야 한다 (`PRESENTATION_1110` §10) |
| 1109 vs 1110 수치 | `EX_ID_PPA_COMPARE_20261109.md` (EX 2.3 / ID 3.0 ns)와 1110 (1.62 / 2.36 ns)은 둘 다 R1.4 flow지만 CORE가 다르다. 같은 표에 넣으려면 "개선 전/후" 로 나눈다 |
| v2 프로그램 | `int8_opt64v2`, `int8_fastv2` 는 tar 안에만 있고 서버 미측정이다. 메모에 적힌 `1110_compare/README.md` 의 "v2" 설명은 tar 판 README에 없다. 로컬 `Project_1/1110_compare/` 폴더도 지금 작업 트리에 없다 |
| 끊긴 참조 | `PRESENTATION_COMPARE_KO.md` 와 `EX_ID_PPA_COMPARE_20261109.md` 가 `starter_giho/...` 를 근거로 들지만 그 폴더는 git HEAD 에만 있다 |
| 공식 도구 수정 | 제출 폴더 `tools/run_flow.py`, `check_release.py`, `trim_vcd.py` 가 원본 ZIP과 다르다(Python 3.6 호환을 위한 한두 줄 변경) |
| 낡은 문구 | tar 안 `1110_compare/README.md` 는 "서버 실행 아직 안 함" 이라고 쓰여 있다. `HANDOVER` 는 R1.3a 를 기준 명세로 적었다. `참고/*/README.md` 경로는 `class-2026-2\`. `참고/*` 의 zip/tar.gz 는 11-04 판(R1.4 이식 전) |
| 버전 표기 | Starter README "Release 1.1" vs 같은 폴더 계약서 "Release 1.2" |
