# 1020_RISC_PIPELINE — EE362 Project 1 INT8 선형계층 (5단 파이프라인 RV32I, 기본 8명령)

결정사항·명세·측정값은 **[SPEC.md](SPEC.md)**. 이 파일은 돌리는 법만.
단일 사이클 판(`../1020_RISC`)과 CORE.v 만 다르고 나머지 파일·절차는 같다. 두 폴더를 같은 서버 흐름으로 돌려 T/A/P 를 비교한다.

```
1020_RISC_PIPELINE/
├── rtl/        TOP.v(연결 완성) CORE.v(5단 파이프라인) CONTROLLER.v(구현) IMEM.v DMEM.v(무수정)
├── sim/        tb_top_demo.v MEMORY_POWER.v(무수정)  tb_ctrl.v(디코드 self-check)  DUMP_CORE.v(VCD)
├── sw/         int8_fast.s(기본안 192 word)  int8_small.s(대안 48 word)  baseline_int8_fc_slow.s(기준본)
├── cases/      공개 16 case (starter 그대로)
├── tools/      rv32i_assembler.py reference_run.py(starter)  verify.py(16 case 기능 검사)  summarize.py(cycles.csv)
├── syn/        synth.tcl CORE.sdc setup.tcl run_synth.sh   (DC, 대상 = CORE)
├── results/    functional_*.json  cycles.csv
├── run.sh      서버(VCS)   run.ps1  로컬(ModelSim ASE)   make_pkg.py  zip/tar.gz 생성
```

## 로컬 (Windows, ModelSim ASE)

```powershell
cd C:\Users\GH\Desktop\class-2026-2\1020_RISC_PIPELINE
.\run.ps1                       # 어셈블 -> Python 16 case -> tb_ctrl -> ModelSim 3프로그램 x 16 case -> 요약표
.\run.ps1 -Progs int8_fast      # 하나만
```

## 서버 (Linux, VCS + DC)

```bash
unzip ~/1020_RISC_PIPELINE.zip -d ~/DICE && cd ~/DICE/1020_RISC_PIPELINE
bash run.sh 100                 # F_MHZ=100 으로 시뮬. 끝에 요약표 (PASS 48/48, TB_CTRL PASS=34 FAIL=0 이어야 함)
cd syn && bash run_synth.sh 8 6 5 4 3.5 3   # CORE 합성, 주기(ns) 여러 개 탐색 -> reports/P<주기>/ + slack 표
cd .. && python3 tools/pj1_check.py        # setup·hold 만족 최소 주기로 T/A/P (재시뮬 불필요)
cd .. && DUMP=1 bash run.sh 200 # (선택) 정한 주파수로 다시 돌리며 syn/core.saif 생성 -> 합성 재실행하면 활동률 반영 전력
```

- 실행기는 자동 선택: `vcs` 가 없으면 서버 wrapper `vcs_queue`(slurm 큐), DC 는 `dc_shell_queue`. 컴파일한 simv 를 직접 못 돌리면 case 마다 `vcs_queue -R` 로 돌린다(느림). 강제: `VCS=vcs_queue MODE=queue bash run.sh`, `DC=dc_shell bash syn/run_synth.sh`. 큐 대기 상태는 `synopsys_queue_status`.
- 결과: `results/cycles.csv`(프로그램×case cycle/LD/ST), `syn/reports/{qor,timing_max,timing_min,area,power}.rpt`.
- 선언 주파수를 정하면 `python3 tools/summarize.py <F_MHZ>` 로 메모리 전력·T 를 다시 계산한다.

## 기능검사 TB · 합성 (R1.3a 반영, 2026-11-04)

- `run.sh` / `run.ps1` 은 tb_top_demo 뒤에 `sim/tb_pj1.v` 로 한 번 더 돈다: 프로그램 × 16 case, random_00 실행 도중 RESET 재인가, `sw/hazard_test.s` (포워딩·lw-use·분기 flush·JAL 링크·x0 지향 시험, wrong-path 에 금지영역 store).
- `tools/pj1_check.py` 가 store 순서·주소·데이터와 DONE 시점 DMEM 전체를 ISA 모델과 비교하고, cycle 을 `N + 3 + lw-use + 2×taken` (5단) / `N` (단일) 모델과 맞춰 본다. 끝 줄이 `PJ1_CHECK PASS 52/52` 이어야 함.
- 합성 corner 는 SS 0.95 V 125 °C, 제약은 R1.3a 공통 SDC 숫자를 CORE 포트(INSTR/READDATA 입력)에 적용한 `syn/CORE.sdc` (원문 `syn/Project1_INT8_CPU_ONLY_20261023.sdc`). RESET 은 compile 뒤 `set_case_analysis 0`.
- 두 폴더(1020_RISC, 1020_RISC_PIPELINE)를 같은 상위 폴더에 풀어 두면 `pj1_check.py` 가 단일/파이프라인 비교표도 찍는다.
- `tools/make_cases.py` : R1.3a starter 의 case 생성기 (숨김 case 대비 랜덤 회귀용).

## 패키지 만들기

```powershell
python make_pkg.py              # 1020_RISC_PIPELINE.zip, 1020_RISC_PIPELINE.tar.gz (build/, work/, 로그 제외)
```
