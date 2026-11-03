# 1020_RISC — EE362 Project 1 INT8 선형계층 (단일 사이클 RV32I, 기본 8명령)

결정사항·명세·측정값은 **[SPEC.md](SPEC.md)**. 이 파일은 돌리는 법만.

```
1020_RISC/
├── rtl/        TOP.v(연결 완성) CORE.v(무수정) CONTROLLER.v(구현) IMEM.v DMEM.v(무수정)
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
cd C:\Users\GH\Desktop\class-2026-2\1020_RISC
.\run.ps1                       # 어셈블 -> Python 16 case -> tb_ctrl -> ModelSim 3프로그램 x 16 case -> 요약표
.\run.ps1 -Progs int8_fast      # 하나만
```

## 서버 (Linux, VCS + DC)

```bash
unzip ~/1020_RISC.zip -d ~/DICE && cd ~/DICE/1020_RISC
bash run.sh 100                 # F_MHZ=100 으로 시뮬. 끝에 요약표 (PASS 48/48, TB_CTRL PASS=34 FAIL=0 이어야 함)
cd syn && bash run_synth.sh     # CORE 합성. synth.tcl 의 PERIOD 를 바꿔 가며 slack>=0 인 최소 주기 탐색
cd .. && DUMP=1 bash run.sh 200 # (선택) 정한 주파수로 다시 돌리며 syn/core.saif 생성 -> 합성 재실행하면 활동률 반영 전력
```

- 실행기는 자동 선택: `vcs` 가 없으면 서버 wrapper `vcs_queue`(slurm 큐), DC 는 `dc_shell_queue`. 컴파일한 simv 를 직접 못 돌리면 case 마다 `vcs_queue -R` 로 돌린다(느림). 강제: `VCS=vcs_queue MODE=queue bash run.sh`, `DC=dc_shell bash syn/run_synth.sh`. 큐 대기 상태는 `synopsys_queue_status`.
- 결과: `results/cycles.csv`(프로그램×case cycle/LD/ST), `syn/reports/{qor,timing_max,timing_min,area,power}.rpt`.
- 선언 주파수를 정하면 `python3 tools/summarize.py <F_MHZ>` 로 메모리 전력·T 를 다시 계산한다.

## 패키지 만들기

```powershell
python make_pkg.py              # 1020_RISC.zip, 1020_RISC.tar.gz (build/, work/, 로그 제외)
```
