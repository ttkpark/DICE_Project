# 1020_RISC_PIPELINE — Project 1 INT8 선형계층, 5단 파이프라인 판 명세

작성 2026-10-20. 단일 사이클 판 `../1020_RISC/SPEC.md` 의 결정(D2~D10: 기본 8명령, 비트 직렬 곱, 프로그램 2종, SDC, 검증 3단, 멀티코어 안 함)을 그대로 상속하고, **D1(CORE 무수정)만 뒤집어 CORE 를 5단 파이프라인으로 바꿨다.** 바뀐 파일은 `rtl/CORE.v` 와 `sw/*.s` 의 `done:` 블록(lw 3개 선행)뿐. TOP/CONTROLLER/IMEM/DMEM/sim 은 byte 단위로 동일.

## 0. 결론 한눈에 (로컬 RTL, 공개 16 case)

| 지표 | 단일 사이클 `1020_RISC` | **파이프라인 `1020_RISC_PIPELINE`** | 비율 |
|---|---:|---:|---:|
| int8_fast 평균 DONE cycle | 552.5 | **636.2** | ×1.152 |
| int8_fast 최대 cycle | 656 | 688 | |
| int8_small 평균 DONE cycle | 729.5 | 929.2 | ×1.274 |
| baseline 평균 cycle | 8,135.7 | 12,170.1 | ×1.496 (분기 많음) |
| LOAD+STORE 집계 (fast, 16 case, TB 계수) | 880 | 1,072 | fetch 기준 계수라 stall/flush 재fetch 포함 |
| 기능 PASS | 48/48 + tb_ctrl 34 | **48/48 + tb_ctrl 34** | |

**파이프라인이 이기는 조건**: 같은 SDC 에서 `f_pipe / f_single > 1.152`(fast 기준). 단일 사이클은 `INSTR 입력지연 0.4T + 디코드 + 레지스터 + ALU + ALURESULT 출력지연 0.4T` 가 한 주기에 들어가야 하므로 논리에 0.2T 만 남는다. 파이프라인은 입력·출력 지연이 같은 경로에 겹치지 않아(§2.3) f 가 크게 오를 것으로 예상. 확정은 서버 DC 두 번(두 폴더) 돌려 §4 산식으로 한다.

## 1. 결정사항 (추가/변경분)

| # | 결정 | 이유 |
|---|---|---|
| P1 | **Harris & Harris 7.5 구조의 5단(IF/ID/EX/MEM/WB)** | 수업 교재 구조라 발표 설명·질의응답이 쉽다. 포트 계약: `PC`=IF fetch 주소, `ALURESULT/WRITEDATA/MEMWRITE`=MEM 단계 레지스터 출력 → DMEM 과 채점기가 보는 store 신호가 한 cycle 동안 안정. |
| P2 | **CONTROLLER 무수정, ZERO 입력을 1 로 묶음** | 디코드는 ID 에서 하고 ZERO 는 EX 에서 나오므로 `PCSRC` 출력을 "분기 또는 점프" 로 쓰고 EX 에서 `PCSrcE = BranchJumpE & (JumpE | ZeroE)`. JumpE 는 `IMMSRC==11`(J 형 = JAL). 제어 진리표·불법 명령 처리(tb_ctrl 34 벡터)는 단일 사이클 판과 동일. |
| P3 | **데이터 해저드: EX 포워딩(MEM→EX, WB→EX) + lw-use 1 cycle stall** | 포워딩 조건 `Rs≠0 & Rs==Rd & RegWrite`. MEM 에서 포워딩할 값은 JAL 이면 PC+4, 그 외 ALU 결과(lw 는 stall 때문에 MEM→EX 포워딩 대상이 되지 않음). 레지스터 파일은 write-first(WB 가 쓰는 번지를 ID 가 읽으면 쓰는 값). |
| P4 | **제어 해저드: BEQ/JAL 모두 EX 해결, taken 이면 IF/ID·ID/EX flush (2 cycle)** | ID 에서 비교하면 EX 의 ALU 결과를 ID 로 끌어와야 해 주기가 늘어난다. 프로그램의 taken 분기(비트가 0 인 bit test, 루프 jal) 당 2 cycle 손실이 §0 의 +15% 의 대부분. |
| P5 | **버블 = IF/ID 에 INSTR=0** | CONTROLLER 가 0x00000000 을 ILLEGAL 로 디코드해 모든 제어가 0. 별도 NOP 인코딩·valid 비트 불필요. |
| P6 | **RESET 동기, 모든 파이프라인 레지스터·레지스터 파일 0 초기화** | 계약(동기 active-high, PC=0). 리셋 직후 MEM 단계 `MEMWRITE=0` 보장. |
| P7 | **프로그램 알고리즘 유지, `done:` 의 lw 3개를 store 앞에 모음** | lw-use stall 2개 제거(−2 cycle). 명령 수·IMEM word 수(192/48)는 그대로. 비트 검사 분기를 없애는 branch-free 식(`-(x&2^k) & (w<<k)`)은 비트당 10 명령으로 분기 평균 5 cycle 보다 비싸 기각. |
| P8 | **계약 해석 위험을 안고 간다** | 계약의 "CPU 내부 변경 허용" 문구는 "선택 명령 구현에 필요한" 범위라, 파이프라인은 해석 분쟁 소지(단일 사이클 판 D1 의 이유). 고정 모듈 포트·RESET 의미·메모리 계약·testbench 는 모두 지켰고 `PC/INSTR/MEMWRITE/ALURESULT/WRITEDATA` 관찰도 그대로 된다. 제출 전 조교에게 "CORE 내부 파이프라인 허용 여부" 를 확인하고, 불허면 `1020_RISC` 를 제출한다. |

## 2. 명세

### 2.1 단계별 신호 (rtl/CORE.v)

| 단계 | 하는 일 | 계약 포트 |
|---|---|---|
| IF | `PC` 레지스터, `PCNextF = PCSrcE ? PCTargetE : PC+4`, stall 시 유지 | `PC` 출력 → IMEM.ADDR, `INSTR` 입력 → IF/ID |
| ID | CONTROLLER(ZERO=1), rf 읽기(write-first), imm 확장, `lwStall` 계산 | |
| EX | 포워딩 mux → ALU(add/sub/and) → ZeroE, `PCSrcE`, `PCTargetE = PCE + ImmExtE` | |
| MEM | EX/MEM 레지스터를 그대로 출력, `READDATA` 를 MEM/WB 에 저장 | `ALURESULT`, `WRITEDATA`, `MEMWRITE` 출력, `READDATA` 입력 |
| WB | `ResultW = {ALU, READDATA, PC+4}[ResultSrcW]`, `rf[RdW] <= ResultW` (RdW≠0) | |

해저드 유닛:
```
lwStall = ResultSrcE[0] & RegWriteE & (RdE != 0) & ((Rs1D == RdE) | (Rs2D == RdE))
StallF = StallD = lwStall      FlushD = PCSrcE      FlushE = lwStall | PCSrcE
ForwardAE = (Rs1E!=0 & Rs1E==RdM & RegWriteM) ? 10 : (Rs1E!=0 & Rs1E==RdW & RegWriteW) ? 01 : 00   (B 동일)
```

### 2.2 cycle 산식 (RTL 측정과 일치)

16 case 전부 정확히 맞는 식 (`p = Σᵢ popcount(X[i] & 0xFF)`, 0..64):

| | 단일 사이클 | 파이프라인 | 차이 |
|---|---|---|---|
| int8_fast | `432 + 4p` | `576 + 2p` | `144 − 2p` = taken bit-test 분기 `2·(64−p)` + 상수 16(채움 3, 루프 taken 분기 4×2, 시작부 lw-use stall 1, 기타 4) |
| int8_small | `609 + 4p` | `869 + 2p` | `260 − 2p` (비트 루프의 `jal loop_bit` 56회 taken 이 추가) |

최악(X 전부 −1, p=64) fast 704 / small 997, 최선(p=0) 576 / 869. 비트가 1 이면 두 판이 같은 비용(add 4)이고 0 이면 파이프라인만 flush 2 cycle 을 내므로, p 가 클수록 손실이 작다(negative_extreme 464→592, max_positive 656→688).

### 2.3 타이밍 경로 (SDC 기준, 입출력 지연 0.4T)

| 경로 | 단일 사이클 | 파이프라인 |
|---|---|---|
| INSTR 입력 → … → ALURESULT 출력 | 0.4T + 디코드 + rf + ALU + 0.4T (논리 0.2T) | 없음. INSTR → IF/ID 레지스터(0.4T + 0) |
| 레지스터 → 출력 | — | PC, ALURESULT, WRITEDATA, MEMWRITE 모두 레지스터 직결 (0.4T 출력지연만) |
| READDATA 입력 → rf 쓰기 | 0.4T + result mux + rf | READDATA → MEM/WB 레지스터 (0.4T + 0) |
| 내부 최장 (예상) | — | 포워딩 mux(3:1) → ALU 32b → ZeroE → PCSrc mux → PC 레지스터 |

따라서 파이프라인의 최소 주기는 내부 ALU 경로가 정하고, 단일 사이클은 입출력 지연이 정한다.

### 2.4 LOAD/STORE 집계 주의

`sim/MEMORY_POWER.v`(무수정, 공식도 동일 방식으로 추정)는 **IF 의 INSTR opcode** 로 LOAD/STORE 를 센다. 파이프라인에서는 lw-use stall 중 재fetch 와 taken 분기 뒤 wrong-path fetch 가 추가로 집계되어 fast 는 50+5 → 평균 59+8 로 늘어난다. P_mem 영향은 100 MHz 에서 +0.003 mW 수준(§0 표: 2.390 → 2.397). 실제 DMEM 접근은 단일 사이클과 같다.

## 3. 검증 (D9 그대로, 결과)

| 단 | 내용 | 결과 |
|---|---|---|
| ① Python ISA 모델 | `tools/verify.py` 16 case × 3 프로그램 (정답·쓰기범위·입력보존·DONE 순서) | 48/48 PASS |
| ② RTL (ModelSim ASE) | `tb_top_demo.v` 16 case × 3 프로그램 | 48/48 PASS, `results/cycles.csv` |
| ③ CONTROLLER 디코드 | `sim/tb_ctrl.v` 34 벡터 | PASS=34 FAIL=0 |

해저드 커버리지: 포워딩(and→beq, add 연쇄, addi→beq 2칸), lw-use stall(`done:` 재배치 전 2회 발생·정상 동작 확인), taken BEQ/JAL flush(bit test·루프), JAL 포워딩(코드에 없음 — P3 의 mux 로 처리, 미검증).

## 4. 서버에서 할 일과 최종 선택

1. 두 폴더 모두 `bash run.sh 100` → 48/48, tb_ctrl 34 확인.
2. 두 폴더 모두 `cd syn && bash run_synth.sh` 로 `PERIOD` 를 줄여가며 setup/hold slack ≥ 0 인 최소 주기 탐색 → `f_single`, `f_pipe`, 각 `area.rpt`, `power.rpt`.
3. 선택 산식(계약 S_25, 우리 팀 내부 비교): `T = 평균cycle/f`, `A = CPU area + 78,020(fast)`, `P = CPU power@f + P_mem(f)`.
   - 파이프라인은 레지스터 약 +330 FF(IF/ID 96, ID/EX ~170, EX/MEM ~70, MEM/WB ~100) 와 포워딩 mux 만큼 A·P 가 늘고, f 를 올리면 CPU 동적전력도 비례해 는다. 배점이 T 2 : A 1 : P 1 이므로 `f_pipe/f_single` 이 1.15 를 조금 넘는 정도면 단일 사이클이 유리할 수 있고, 1.5 이상이면 파이프라인이 유리. 수치를 넣어 결정.
4. `DUMP=1 bash run.sh <F_MHZ>` 로 `syn/core.saif` 생성 후 재합성 → 활동률 반영 전력.
5. P8 의 조교 확인. 제출은 둘 중 하나만.
