# EE362 Project 1 INT8 선형계층 평가 계약

배포일: 2026-10-20 · Release 1.2. 이 문서는 인터페이스, 명령어, 메모리 PPA 산식 및 상대평가 규칙을 고정한다. 공식 채점기는 별도 보관하며 학생이 수정할 수 없다.

## 한눈에 보는 고정 조건

| 항목 | 계약 |
|---|---|
| 계산 | `Y[j] = BIAS[j] + sum(X[i] * W[j][i])`, `i=0..7`, `j=0..3` |
| 입력 | signed INT8 값의 32비트 부호 확장 word 저장. `BIAS`와 `Y`는 signed INT32 |
| 명령어 범위 | 기본 8개(`ADD`, `SUB`, `AND`, `ADDI`, `LW`, `SW`, `BEQ`, `JAL`)는 필수. Harris 부록 B 표 B.1의 나머지 RV32I 명령은 선택 구현·사용 허용 |
| 학생 수정 범위 | `CONTROLLER`와 `TOP`의 명시적 연결, 어셈블리. 선택 명령 구현에 필요한 CPU 내부 데이터패스·ALU·레지스터 파일 수정 허용. 고정 모듈의 외부 포트 계약은 유지 |
| 채점 경계 | 아래 모듈명·포트명·방향·폭, `RESET` 의미, 메모리 주소·완료 계약 |
| 메모리 | IMEM은 프로그램 길이에 따라 64/256/512 × 32비트 SRAM 상당량, DMEM은 512 × 32비트 고정 |
| PPA | `T = 평균 DONE cycle / f`, `A = CPU cell area + SRAM 상당 면적`, `P = CPU 평균전력 + SRAM 동적전력 + SRAM 정적전력 추정치` |
| 배점 | 프로젝트 1 PPA 25점, 발표 피어리뷰 10점. 프로젝트 2에도 같은 배점 적용. 1주차 수업 전체 성적표의 프로젝트 명세 50점과 피어리뷰 20점에 각각 대응 |

일정과 마감은 수업 공지에서 안내한다.

## 명령어와 기능 판정

- 기본 8개 명령의 구현은 필수다. 추가 구현은 Harris & Harris 부록 B 표 B.1에 실린 **RV32I 32비트 기본 정수 명령**으로 한정한다. 예를 들어 `SLL/SRL/SRA`, `SLT/SLTU`, `OR/XOR`, `BNE/BLT/BGE`, `JALR`, `LUI`, `LB/LH/LBU/LHU/SB/SH`를 표준 인코딩과 동작 그대로 선택 구현할 수 있다. 선택 명령의 개수 자체에는 가산점이 없다.
- `MUL`을 포함한 M 확장 전체(`MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU` 포함), RV64I, 부동소수점 F/D, 압축 C, CSR·권한 명령, `ECALL/EBREAK`, 사용자 정의 opcode 및 표 B.1 밖의 명령은 허용하지 않는다. Harris의 의사 명령은 실제 ISA 명령이 아니며, 과제 제출용 `.s`에는 사용하지 않는다.
- 제출한 `.s`와 전체 `.hex`를 검사한다. 실행되지 않는 위치의 명령도 같은 범위를 적용한다. 학생은 사용한 선택 명령을 제출물에 명시하고, 해당 명령의 단독 기능 시험을 함께 제출한다. 공식 채점기는 기본 8개를 모든 팀에 검사하고, 선언·사용한 선택 명령은 표준 RV32I 의미로 검증한다. 구현하지 않은 선택 명령과 금지 인코딩을 채점기가 주입했을 때에는 안전한 불법 명령 처리(`ILLEGAL=1`, 상태 변경 없음)를 유지해야 한다. 제출 프로그램에 금지 명령이 있으면 실행 여부와 관계없이 기능 검사에서 실패한다.
- 현재 제공한 `Project1_INT8_Baseline_20261007`의 Python 어셈블러·실행 모델은 기본 8개만 지원한다. 선택 명령을 쓰는 `.s`를 이 도구가 거부해도 그것만으로 과제 위반은 아니다. 학생 배포 전에는 선택 명령을 조립·검증할 수 있는 공식 도구 또는 동등한 사용 절차와 채점기를 제공해야 한다. 확장에 필요한 CPU 내부 변경은 허용하지만 `TOP/CORE/CONTROLLER/IMEM/DMEM`의 고정 포트는 변경할 수 없다.
- `x0`은 항상 0을 읽는다. `PC`는 바이트 주소이며, 일반 진행은 `PC+4`; `BEQ`와 `JAL` 목표는 현재 `PC+imm`이다.
- 정답 `Y[0..3]`을 모두 기록한 뒤 설정 블록의 `DONE_ADDR`에 해당 case의 `DONE_TOKEN`을 마지막으로 기록한다. 입력·설정 영역 변경, 정답 lookup, 특정 공개 입력에만 맞춘 동작은 실패다.

## 고정 모듈 인터페이스

모듈명과 모든 기존 포트의 대소문자, 방향, 폭을 변경하지 않는다. 포트를 추가하거나 삭제하지 않는다. 최상위 `TOP`에만 32비트 예약 입력 20개와 예약 출력 20개를 둔다. 공식 testbench는 모든 예약 입력을 `32'b0`에 연결하고 모든 예약 출력은 `.RESERVED_OUTn()`으로 연결하지 않는다. 기능 정답이 예약 입력의 비영값이나 예약 출력의 관찰에 의존해서는 안 된다. 학생은 testbench를 수정할 수 없고, 로컬 복사본을 바꾸더라도 공식 채점에는 반영되지 않는다.

### TOP — 공식 채점기의 연결 대상

```verilog
module TOP (
    input  wire        CLK,
    input  wire        RESET,
    input  wire [31:0] RESERVED_IN0,
    input  wire [31:0] RESERVED_IN1,
    input  wire [31:0] RESERVED_IN2,
    input  wire [31:0] RESERVED_IN3,
    input  wire [31:0] RESERVED_IN4,
    input  wire [31:0] RESERVED_IN5,
    input  wire [31:0] RESERVED_IN6,
    input  wire [31:0] RESERVED_IN7,
    input  wire [31:0] RESERVED_IN8,
    input  wire [31:0] RESERVED_IN9,
    input  wire [31:0] RESERVED_IN10,
    input  wire [31:0] RESERVED_IN11,
    input  wire [31:0] RESERVED_IN12,
    input  wire [31:0] RESERVED_IN13,
    input  wire [31:0] RESERVED_IN14,
    input  wire [31:0] RESERVED_IN15,
    input  wire [31:0] RESERVED_IN16,
    input  wire [31:0] RESERVED_IN17,
    input  wire [31:0] RESERVED_IN18,
    input  wire [31:0] RESERVED_IN19,
    output wire [31:0] PC,
    output wire [31:0] INSTR,
    output wire        MEMWRITE,
    output wire [31:0] ALURESULT,
    output wire [31:0] WRITEDATA,
    output wire [31:0] RESERVED_OUT0,
    output wire [31:0] RESERVED_OUT1,
    output wire [31:0] RESERVED_OUT2,
    output wire [31:0] RESERVED_OUT3,
    output wire [31:0] RESERVED_OUT4,
    output wire [31:0] RESERVED_OUT5,
    output wire [31:0] RESERVED_OUT6,
    output wire [31:0] RESERVED_OUT7,
    output wire [31:0] RESERVED_OUT8,
    output wire [31:0] RESERVED_OUT9,
    output wire [31:0] RESERVED_OUT10,
    output wire [31:0] RESERVED_OUT11,
    output wire [31:0] RESERVED_OUT12,
    output wire [31:0] RESERVED_OUT13,
    output wire [31:0] RESERVED_OUT14,
    output wire [31:0] RESERVED_OUT15,
    output wire [31:0] RESERVED_OUT16,
    output wire [31:0] RESERVED_OUT17,
    output wire [31:0] RESERVED_OUT18,
    output wire [31:0] RESERVED_OUT19
);
```

`RESET`은 상승 에지에서 적용되는 active-high 동기 reset이다. reset 후 첫 명령 주소 `PC=0`. 공식 채점기는 `PC`, `INSTR`, `MEMWRITE`, `ALURESULT`, `WRITEDATA`로 명령 진행과 메모리 쓰기를 관찰한다. `DONE`은 별도 포트가 아니라 지정 주소로의 마지막 store로 판정한다.

`rtl/TOP.v`의 포트 선언은 고정이다. 학생은 내부 TODO 연결을 완성하되 포트 목록을 고치지 않는다. 제공한 `sim/tb_top_demo.v`는 연습용이고, 실제 평가는 별도 보관한 변경 불가능한 testbench로 수행한다. 두 testbench 모두 예약 입력은 0, 예약 출력은 open connection이다.

### CORE

| 방향 | 이름 | 폭 |
|---|---|---:|
| 입력 | `CLK`, `RESET` | 각 1 |
| 입력 | `INSTR`, `READDATA` | 각 32 |
| 출력 | `PC`, `ALURESULT`, `WRITEDATA` | 각 32 |
| 출력 | `MEMWRITE` | 1 |

### CONTROLLER

| 방향 | 이름 | 폭 |
|---|---|---:|
| 입력 | `INSTR` | 32 |
| 입력 | `ZERO` | 1 |
| 출력 | `REGWRITE`, `MEMWRITE`, `ALUSRC`, `PCSRC`, `ILLEGAL` | 각 1 |
| 출력 | `RESULTSRC`, `IMMSRC` | 각 2 |
| 출력 | `ALUCTRL` | 3 |

### IMEM과 DMEM

| 모듈 | 입력 | 출력 |
|---|---|---|
| `IMEM` | `ADDR[31:0]` | `INSTR[31:0]` |
| `DMEM` | `CLK`, `MEMWRITE`, `ADDR[31:0]`, `WRITEDATA[31:0]` | `READDATA[31:0]` |

`IMEM`과 `DMEM`은 기능 시뮬레이션 모델로 제공하며 CPU cell 합성 면적에서 제외한다. 메모리 면적·동적전력·정적전력 추정치는 아래의 동일한 SRAM 상당량으로 모든 팀에 가산한다. starter의 포트 선언과 이 표가 다르면 배포 전에 먼저 수정해야 하며, 둘을 혼용해 채점하지 않는다.

제공한 Verilog `sim/MEMORY_POWER.v`는 DONE까지 실행한 cycle 수, 모든 허용 load/store 접근 수, HEX에서 읽은 IMEM word 수, 학생이 선언한 `F_MHZ`를 사용하여 아래 **수업용 메모리 동적·정적전력 추정값**을 자동 출력한다. 물리적 SRAM timing이나 CPU cell 전력을 측정하는 모듈은 아니다. 따라서 `T=cycle/f`에 별도의 async delay를 임의로 더하지 않는다. 사용 주파수는 별도 setup/hold STA 조건을 만족해야 한다.

## 메모리 용량 및 PPA 가산

공통 기준은 교육용 Synopsys SAED 32/28 nm `SRAM1RW` 매크로의 SS 0.95 V, 125 °C 라이브러리다. 아래 면적은 해당 매크로의 Liberty `area` 값이다. 라이브러리 자체는 배포하지 않는다.

| 제출한 IMEM `.hex` word 수 | 채택 IMEM 매크로 | IMEM 면적 [µm²] | DMEM 면적 [µm²] | 메모리 면적 가산 [µm²] | IMEM 접근 에너지 [pJ] |
|---:|---|---:|---:|---:|---:|
| 1–64 | `SRAM1RW64x32` | 8,713.50 | 50,667.68 | 59,381.18 | 2.23 |
| 65–256 | `SRAM1RW256x32` | 27,352.30 | 50,667.68 | 78,019.98 | 7.00 |
| 257–512 | `SRAM1RW512x32` | 50,667.68 | 50,667.68 | 101,335.36 | 12.97 |

`DMEM`은 모든 팀에서 `SRAM1RW512x32` 하나로 고정한다. `.hex`는 첫 줄이 주소 0의 명령이고, 한 줄에 8자리 16진수 word 하나씩 빈 주소 없이 기록한다. 0개 또는 512개 초과이면 실패. IMEM 비용은 파일의 길이로 정하며, 실행 중 실제 fetch가 적더라도 용량 비용은 줄지 않는다.

면적 가산식은 다음과 같다.

```text
A_total [µm²] = A_CPU_cell [µm²] + A_IMEM_macro [µm²] + 50,667.68 [µm²]
```

동적전력은 *채점용 접근 에너지 추정값*이다. 256 × 32비트 매크로의 읽기당 기준 에너지를 7.00 pJ로 놓고, 같은 폭의 다른 용량은 해당 매크로 면적 비율로 환산한다. DMEM의 read와 write 모두 접근 1회당 12.97 pJ로 동일하게 계산한다. 정적전력은 SAED32 매크로의 위 `area` 값에 비례하는 **수업용 채점 추정치**로 정의한다. 배포 가능한 SRAM Liberty 자료에 신뢰할 누설전력 값이 없어 계수 `0.020 mW / 1,000 µm²`는 교강사가 고정한 평가 정책이지 EDK 실측 누설전력 값이 아니다. 전 팀에 같은 식을 적용하며, 수업 중 계수를 바꾸지 않는다. 실제 실리콘 전력 또는 특정 SRAM의 PVT 누설전력이라고 해석하지 않는다.

```text
E_IMEM [pJ/access] = 7.00 × A_IMEM_macro / 27,352.30
E_DMEM [pJ/access] = 12.97
r_D = sum_over_cases(load_count + store_count) / sum_over_cases(DONE_cycle_count)
P_mem_dynamic [mW] = f_MHz / 1000 × (E_IMEM + E_DMEM × r_D)
P_mem_static_proxy [mW] = 0.020 × (A_IMEM_macro + 50,667.68) / 1,000
P_mem [mW] = P_mem_dynamic + P_mem_static_proxy
P_total [mW] = P_CPU_report [mW] + P_mem [mW]
T [s] = mean_over_cases(DONE_cycle_count) / (f_MHz × 1,000,000)
```

기능·PPA는 동일한 공통 24개 case를 사용한다. IMEM은 매 실행 cycle마다 1회 fetch, DMEM은 허용된 모든 RV32I load/store(`LB/LH/LW/LBU/LHU/SB/SH/SW`)를 각 1회 접근으로 센다. 출력 로그는 `LOAD`, `STORE` 전체 횟수를 기록한다. 모든 팀은 단일 동작주파수 `f_MHz`를 선언하고, 동일 조건의 CPU setup/hold STA를 통과해야 한다. CPU 전력 보고서도 그 주파수와 동일한 입력 activity로 산출한다. `park` cycle은 시간·전력 측정에서 제외한다.

예: 57-word 프로그램, 900 cycle, `LW=110`, `SW=37`, `f=100 MHz`라면 메모리 면적은 `59,381.18 µm²`, 메모리 동적전력은 약 `0.435 mW`, 정적전력 추정치는 `1.188 mW`, 합계는 약 `1.623 mW`다. 같은 활동률에서 `f=200 MHz`이면 동적전력은 약 `0.870 mW`로 늘지만 정적전력 추정치는 `1.188 mW`로 같다. IMEM이 512 word이면 정적전력 추정치만 `2.027 mW`가 되어 더 큰 용량에 지속적인 불이익이 생긴다. 이 값은 CPU의 면적·전력 보고서에 **더하는** 값이다.

## 평가와 제출

기능 정확성, 제어유닛·TOP 연결, 재현 및 개선 근거, 고정 포트·ISA 준수, CPU 합성과 선언 주파수의 setup/hold를 각각 **PPA 참가 PASS/FAIL**로 판정한다. 기능은 공통 공개·숨김 24개 case를 모두 통과해야 한다. 개선 근거는 동일 조건의 변경 전후 T/A/P와 소스·로그로 재현 가능해야 한다. 어느 관문이든 FAIL이면 PPA 비교에 참가하지 못하고 PPA 점수는 0/25점이며, 모든 PASS 팀 뒤의 공동 최하위로 둔다. PPA 관문에는 부분점수가 없다. 발표·질의응답은 이 관문에서 제외한다.

PASS 팀끼리만 상대평가한다. `T_best`, `A_best`, `P_best`는 각각 PASS 팀의 최솟값이며, 한 팀이 세 항목 모두 최고일 필요는 없다. 팀 `i`의 프로젝트 1 PPA 점수는 아래 25점 만점 식이다. 성능:면적:전력 배점은 정확히 **2:1:1**이다. e-Campus에서 100점 척도를 써야 하면 `S_100 = S_25 × 100/25`로만 환산한다. 동점은 동점으로 둔다.

```text
S_25(i) = 12.50 × min(1, T_best/T_i)
        +  6.25 × min(1, A_best/A_i)
        +  6.25 × min(1, P_best/P_i)
```

`T`, `A`, `P`는 모두 양수이며 작은 값이 좋다. 기능·제어·재현은 PPA 참가 관문이지만 별도 점수가 없다. 위 `A_total`과 `P_total`을 모든 팀에 같은 방식으로 적용한다.

### 발표 피어리뷰 10점

프로젝트 1 발표는 동료 학생이 평가한다. PPA 수치의 높낮이를 피어리뷰에서 중복 채점하지 않고, 설계와 결과를 이해할 수 있게 설명했는지를 본다. 평가 요소는 ① 고정 인터페이스·제어 흐름에 대한 설계 설명, ② `Y`·`DONE`과 검사 범위를 보여주는 기능 증거, ③ 동일 조건에서 기준본과 개선본의 T/A/P 비교, ④ 코드 변경과 지표 변화의 연결, ⑤ 파일·명령·조건을 포함한 재현 절차, ⑥ 구현의 한계와 trade-off에 대한 질의응답이다. 발표 피어리뷰는 PPA PASS/FAIL 관문과 분리한다. 동료 평가의 세부 양식과 집계 방식은 수업 공지에서 안내한다.

제출물에는 `TOP`, `CORE`, `CONTROLLER` RTL과 수정한 CPU 내부 모듈, 어셈블리 원본 `.s`, 재생성된 `.hex`·`.lst`, 사용한 선택 RV32I 명령 목록과 단독 기능 시험, 기능 로그, STA·CPU area·CPU power 보고서, 선언 주파수, 실행 cycle 및 load/store 횟수, 선택된 IMEM 용량, 재현 절차를 포함한다. 예약 입력의 비영값에 의존하는 기능, 고정 포트 계약 위반, 금지 명령 사용 또는 선언한 선택 명령의 오동작이 발견되면 기능 점검에서 실패 처리한다.
