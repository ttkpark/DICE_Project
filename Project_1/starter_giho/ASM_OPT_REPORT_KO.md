# Project 1 ASM 최적화 보고서 — `int8_opt64.s`

작성 2026-11-03. 대상: `Project_1/starter_giho/`. 근거 수치는 모두 이 폴더의 Python ISA 모델(`tools/reference_run.py`)과 `참고/1020_RISC*/results/cycles.csv`(팀 RTL 실측)에서 나온 값이다. 파이프라인 cycle 중 `int8_opt64` 값만 추정치다(§5).

## 1. 결과 요약 (공개 16 case 평균)

| 프로그램 | word (IMEM 매크로) | 단일 사이클 cycle | 5단 파이프라인 cycle | load+store / case | cycle 식 |
|---|---:|---:|---:|---:|---|
| `baseline_int8_fc_slow` (starter 기준본) | 57 (64) | 8,135.7 | 12,170.1 | 147 | `730 + 4·Σ|W| + (음수 W 수)` |
| `int8_small` (기존, 참고 폴더) | 48 (64) | 729.5 | 929.2 | 55 | `609 + 4p` |
| **`int8_opt64` (이번 작업)** | **58 (64)** | **677.9** | **821.4 (추정)** | **55** | **`554 + 4p + n`** |
| `int8_fast` (기존, 참고 폴더) | 192 (256) | 552.5 | 636.2 | 55 | `432 + 4p` |

`p = Σᵢ popcount(X[i] & 0xFF)` (0..64, 랜덤 입력 평균 32), `n` = 음수 X 개수 (0..8). 식은 16 case 전부에서 실측과 정확히 일치한다.

- **기준본 대비**: 단일 사이클 cycle **1/12.0** (−91.7 %), 파이프라인 **1/14.8**. DMEM 접근 147 → 55회. IMEM 용량 구간은 그대로 64 word.
- **같은 64-word 구간의 기존안 `int8_small` 대비**: 단일 사이클 **−51.6 cycle (−7.1 %)**, 파이프라인 **−107.8 cycle (−11.6 %)**.
- **최악/최선 case**: 단일 사이클 594 (`negative_extreme`) ~ 778 (`max_positive`). 랜덤 5,000 case 범위 572 ~ 771.

## 2. 무엇을 바꿨나

알고리즘은 `int8_small`/`int8_fast` 와 같은 **비트 직렬 곱**이다: X[i] 의 비트 k 가 1 이면 네 행의 누산기에 `W[j][i]<<k` 를 더하고(부호 비트 7 은 뺌), `W<<k` 는 `add w,w,w` 로 만든다. X 비트 검사 1회를 4개 행이 공유하므로 곱셈기 없이 (i,j) 쌍당 약 10 cycle 이다. 바뀐 것은 **루프 구조**만이다.

| # | 변경 | word | cycle 효과 (단일 / 파이프라인) |
|---|---|---:|---|
| 1 | 비트 루프를 **2비트씩 펼치고 종료 검사(`mask==128`)를 두 비트 사이**에 둔다. 1~3회차는 `bit(2n) · 검사 · bit(2n+1) · jal`, 4회차는 `bit6 · 검사 → 탈출`. 7비트+부호비트가 딱 2회 반복에 들어간다 | +11 | i 당 beq/jal 13회 → 7회: **−6 / −18 cycle·i** |
| 2 | i 루프 종료 검사를 **루프 머리**로 옮기고, 부호 비트가 0이면 bit7 의 `beq` 가 바로 다음 i 로 간다 (`next_i` 블록 삭제) | 0 | X≥0 인 i 마다 **−1 / −3** |
| 3 | configuration block(0x300) 을 `lw xN, 768(x0)` 처럼 **x0 기준 즉시값**으로 읽는다 (base 레지스터 설정 삭제) | −1 | −1 / −1 |
| 4 | `lw` 바로 다음 명령이 그 결과를 쓰지 않도록 배치 | 0 | 파이프라인 lw-use stall 0회 (small/fast 는 1회) |

왜 "2비트" 인가: 비트 하나의 코드는 `and, beq, add×4, add×4(doubling), add(mask)` = **11 word** 다 (조건부 add 4개는 건너뛰어도 word 는 차지한다). 고정 부분(설정 9 + 종료 8 + park 1 = 18)과 i 당 공통 부분(검사 1 + lw 5 + mask 초기화 1 + bit7 9 = 16)을 빼면 비트 루프에 **30 word** 가 남는다. 1비트/회 = 13, 2비트/회 = 24 (가능), 3비트/회 = 35 (초과). 즉 64 word 안에서 이 알고리즘으로 가능한 최대 펼침이다.

## 3. 어디까지 줄일 수 있나 (한계 분석)

기본 8명령(ADD SUB AND ADDI LW SW BEQ JAL)만으로 8비트×8비트 곱 32개를 하는 데 드는 **고정 일거리**:

| 항목 | cycle | 비고 |
|---|---:|---|
| load (config 6 + X 8 + W 32 + BIAS 4) | 50 | 더 줄일 수 없음 (출력·DONE store 5 별도) |
| 비트 검사 `and+beq` (8비트 × 8 i) | 128 | 4개 행이 공유하므로 이미 최소 |
| W doubling (7회 × 4행 × 8 i) | 224 | 가장 큰 비용 |
| 조건부 add/sub | 4p | 입력 의존, 평균 128 |
| 설정·종료 | ~17 | |
| **완전 펼침 하한** | **≈ 412 + 4p (≈ 540)** | 353 word → IMEM 512 구간 |

- **256-word 구간**: `int8_fast` 432+4p 는 하한에서 20 cycle(루프 4회의 jal/beq) 차이. 더 펼치면 353 word 로 512 구간에 들어가 면적·정적전력만 늘고 cycle 은 −20 이라 손해. **사실상 끝**.
- **64-word 구간**: `int8_opt64` 554+4p+n. 남은 오버헤드는 i 당 mask doubling 7 + 비트루프 분기 7 + mask 초기화 1 + i 루프 검사·포인터 3 = 18 → 8 i 에 144 cycle. 이걸 더 깎으려면 펼침(word)이 필요하고 6 word 밖에 안 남았다. **64 word 안에서는 여기가 한계로 본다** (아래 기각안 참조).

검토 후 기각한 것 (모두 Python 모델로 수치 확인 또는 word 계산):

| 안 | 결과 |
|---|---|
| 비트 3개/회 펼침 | 35 word → 총 69 word, 64 초과 |
| i 2개 동시 처리 (bit 검사·루프 오버헤드 공유) | 68~89 word, 64 초과. 256 구간에서는 `int8_fast` 와 동급 |
| 8비트 균일 루프 + 뒤에서 부호 보정 (`acc -= W<<8`) | bit7 블록은 없어지지만 4회차 doubling 낭비 + 음수마다 add 4 와 sub 4 모두 실행 → i 당 +7 cycle, 더 느림 |
| k(비트) 바깥 루프 + 누산기 Horner (W doubling 제거) | W 32개를 레지스터에 못 올림. 반씩 나누면 비트 검사가 2배(+128), 100 word 이상. 메모리에서 매번 다시 읽으면 load 320회로 전력 손해 |
| 분기 없는 비트 검사 `(W<<k) & -(x & 2^k)` | 비트당 10 cycle 고정 vs 분기 평균 4(단일)/5(파이프라인). 손해 |
| Booth / 부호-숫자 재부호화로 add 수 줄이기 | 랜덤 입력에서 비영 digit 기대값이 popcount 와 같음(4/8). 분기만 늘어남 |
| 음수 X 를 |X| 로 바꿔 popcount 줄이기 | 평균 add −16 cycle 이지만 부호 분기 +16, W 부정 +20 → 손해 |
| 2개 행을 16비트 lane 으로 packing (SIMD) | 누산 결과를 lane 에서 꺼낼 right shift 가 없음(SRL 은 선택 명령). 불가 |
| 선택 명령 (SLLI/BNE/BGE 등) | doubling·검사가 이미 1명령=1cycle. BNE 로 루프당 1 cycle 뿐. 디코더·검증 부담 대비 이득 없음 (인수인계서 §4.3 과 동일 결론) |

## 4. 64 word (`int8_opt64`) 와 256 word (`int8_fast`) 중 무엇을 낼 것인가

계약 산식 `S = 12.5·T_best/T + 6.25·A_best/A + 6.25·P_best/P` 에서 우리 팀 값이 best 라고 두고 두 프로그램의 점수 차를 계산했다 (CPU 면적·전력은 서버 DC 결과가 아직 없어 시나리오).

| 조건 | fast 의 T 이득 | fast 의 A 손실 | fast 의 P 손실 | **fast − opt64** |
|---|---:|---:|---:|---:|
| 단일 사이클, A_cpu 15k µm², P_cpu 1 mW@100 MHz | +2.31 | −1.25 | −1.61 | **−0.55** |
| 단일 사이클, A_cpu 30k, P_cpu 3 mW | +2.31 | −1.08 | −1.01 | **+0.22** |
| 파이프라인, A_cpu 15k, P_cpu 1 mW | +2.82 | −1.25 | −1.61 | **−0.04** |
| 파이프라인, A_cpu 30k, P_cpu 3 mW | +2.82 | −1.08 | −1.01 | **+0.73** |

(f 를 200/250 MHz 로 올려도 동적전력이 양쪽 다 비례해 늘어 결론은 ±0.1 안에서 같다.)

- 차이가 **25점 중 ±0.8점 이내**로 거의 상쇄된다. CPU 가 작고 저전력이면 `int8_opt64`, CPU 면적·전력이 크고 파이프라인이면 `int8_fast` 가 유리하다.
- **결정은 DC 의 `report_area`/`report_power` 가 나온 뒤** 위 식에 실측값을 넣어서 한다. 그 전까지 두 프로그램을 모두 유지한다.
- 메모리 쪽만 보면(100 MHz): `int8_opt64` A_mem 59,381 µm², P_mem 1.516 mW / `int8_fast` A_mem 78,020 µm², P_mem 2.389 mW.

## 5. 검증

| 단계 | 내용 | 결과 |
|---|---|---|
| 어셈블 | `tools/rv32i_assembler.py` (기본 8명령) | 58 word, `.hex`/`.lst` 재생성 |
| 공개 16 case | `tools/verify.py int8_opt64.hex` — 정답, Y/SCRATCH/DONE 밖 store 금지, 입력·config 보존, DONE 순서 | **16/16 PASS** → `results/functional_int8_opt64.json` |
| 숨김 case 대비 랜덤 회귀 | `tools/fuzz.py int8_opt64.hex 3000 7` 및 `2000 99` — `make_cases.py` 와 같은 값 범위·주소 섞기, 1/4 은 극단값(−128/−127/127, BIAS ±2³⁰) | **5,000/5,000 PASS**, cycle 572~771 |
| cycle 식 | `554 + 4p + n` | 16 case 전부 일치 |
| 파이프라인 cycle | 명령 수 + 3(채움) + 2×taken 분기 + lw-use stall 로 추정. 같은 추정기가 팀 RTL 실측(`참고/1020_RISC_PIPELINE/results/cycles.csv`)과 baseline·small 은 **정확히 일치**, fast 는 −4 cycle(0.6 %) | 821.4 (오차 ±4 수준). 로컬에 ModelSim 이 없어 RTL 재실행은 못 함 → **김대현 쪽 RTL 로 확인 필요** |

`verify_all.py` 는 기준본의 고정 실행량(store 37, load 110)을 assert 하므로 쓰지 않았다.

## 6. 재현

```bash
cd Project_1/starter_giho
python tools/rv32i_assembler.py int8_opt64.s -o int8_opt64.hex --listing int8_opt64.lst
python tools/verify.py int8_opt64.hex          # 16 case
python tools/fuzz.py   int8_opt64.hex 3000 7   # 랜덤 3000 case (seed 7)
# RTL: 참고/1020_RISC*/run.ps1 의 -Progs 에 int8_opt64 를 넣고 sw/ 에 복사해 돌리면 cycles.csv 에 들어감
```

## 7. 파이프라인 담당에게 (김대현)

- `int8_opt64` 의 taken 분기는 i 당 `7 + (8 − popcount)` 회 (비트가 0 일 때 skip 분기 + 루프 분기). 파이프라인에서 cycle 의 **약 17 %(144 cycle)가 taken 분기 flush** 다. ASM 쪽에서 이 구조를 바꿀 방법은 없다(분기 없는 식은 더 비쌈). 분기 비용을 줄이는 레버는 CPU 쪽에 있다: ID 단계 분기 해결(1 cycle 손실) 또는 정적 예측 "backward taken".
- lw-use stall 은 0회가 되도록 배치했으니 stall 로직 쪽 여유는 신경 안 써도 된다.
- 단일 사이클 대비 파이프라인이 유리해지는 조건은 `f_pipe / f_single > 821.4 / 677.9 = 1.21` (opt64 기준), `> 1.15` (fast 기준).
