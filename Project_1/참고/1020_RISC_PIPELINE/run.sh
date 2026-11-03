#!/usr/bin/env bash
# 1020_RISC_PIPELINE 서버 실행기.  패키지 루트에서:   bash run.sh [F_MHZ]        기본 F_MHZ=100
#   1) sw/*.s -> .hex/.lst        2) Python ISA 모델로 16 case 기능 검사 (results/functional_*.json)
#   3) CONTROLLER 디코드 self-check (sim/tb_ctrl.v, 34 벡터: 합법 11 + 불법 23)
#   4) VCS 컴파일, 3 프로그램 x 16 case 실행 (build/sim_*.log)   5) results/cycles.csv + 요약표
#   DUMP=1 bash run.sh  : 추가로 int8_fast/random_00 의 CORE VCD -> syn/core.saif (DC 전력 활동률)
#
# VCS 실행기 자동 선택: vcs 가 PATH 에 있으면 vcs, 없으면 수업 서버 wrapper vcs_queue (slurm 큐).
#   강제하려면  VCS=vcs_queue bash run.sh
#   vcs_queue 는 컴파일한 simv 를 로그인 노드에서 직접 못 돌릴 수 있어, 한 번 시험해 보고 안 되면
#   case 마다 "vcs_queue ... -R +PROGRAM=.. " 로 컴파일+실행을 함께 한다 (느리지만 확실).  MODE=queue 로 강제.
set -e
cd "$(dirname "$0")"
F_MHZ=${1:-100}
PROGS="baseline_int8_fc_slow int8_small int8_fast"
RTL="rtl/TOP.v rtl/CORE.v rtl/CONTROLLER.v rtl/IMEM.v rtl/DMEM.v sim/MEMORY_POWER.v sim/tb_top_demo.v"
mkdir -p build results
VFLAGS="-full64 -timescale=1ns/1ps"   # RTL 에는 `timescale 이 없고 sim/ 에만 있어 VCS 가 Error-[ITSFM] 을 냄

if [ -z "$VCS" ]; then
  if   command -v vcs       > /dev/null 2>&1; then VCS=vcs
  elif command -v vcs_queue > /dev/null 2>&1; then VCS=vcs_queue
  else echo "오류: vcs / vcs_queue 둘 다 없음. 수업 서버에서 실행하거나 VCS=<명령> 으로 지정" >&2; exit 2
  fi
fi
echo "VCS 실행기: $VCS"

for p in $PROGS; do
  python3 tools/rv32i_assembler.py sw/$p.s -o sw/$p.hex --listing sw/$p.lst
  python3 tools/verify.py sw/$p.hex
done
set +e      # 서버 wrapper 는 TB 의 FAIL 뒤에도 종료 코드 0 을 줄 수 있으므로 이후는 로그 내용으로 판정한다

# ---- 3) CONTROLLER self-check : 컴파일+실행 한 번 (-R)
$VCS $VFLAGS -top TB_CTRL rtl/CONTROLLER.v sim/tb_ctrl.v -o build/simv_ctrl -R -l build/tb_ctrl.log > /dev/null
grep -E "FAIL|TB_CTRL RESULT" build/tb_ctrl.log

# ---- 4) TOP 시뮬레이션 : 컴파일 1회 후 simv 직접 실행이 되면 그대로, 안 되면 case 마다 -R
sim_args() { echo "+PROGRAM=sw/$1.hex +DATA=cases/$2_dmem.hex +EXPECTED=cases/$2_expected.hex +F_MHZ=$F_MHZ"; }

if [ "$MODE" != "queue" ]; then
  $VCS $VFLAGS -top TB_TOP_DEMO $RTL -o build/simv -l build/compile.log > /dev/null
  rm -f build/probe.log
  ./build/simv $(sim_args int8_fast demo) -l build/probe.log > /dev/null 2>&1
  if grep -q "TB_TOP_DEMO" build/probe.log 2>/dev/null; then MODE=direct; else MODE=queue; fi
fi
echo "시뮬레이션 방식: $MODE  (direct = ./build/simv 반복 실행, queue = case 마다 $VCS -R)"

for p in $PROGS; do
  for c in cases/*.json; do
    n=$(basename "$c" .json)
    log=build/sim_${p}_${n}.log
    rm -f "$log"
    if [ "$MODE" = direct ]; then
      ./build/simv $(sim_args $p $n) -l "$log" > /dev/null 2>&1
    else
      $VCS $VFLAGS -top TB_TOP_DEMO $RTL -o build/simv -R $(sim_args $p $n) -l "$log" > /dev/null 2>&1
    fi
    printf "%-24s %-17s %s\n" "$p" "$n" "$(grep -m1 -E 'PASS TB_TOP_DEMO|FAIL' "$log" 2>/dev/null || echo 'NO RESULT (로그 확인)')"
  done
done
python3 tools/summarize.py $F_MHZ

# ---- (선택) 전력 활동률용 VCD -> SAIF
if [ "${DUMP:-0}" = "1" ]; then
  if [ "$MODE" = direct ]; then
    $VCS $VFLAGS $RTL sim/DUMP_CORE.v -o build/simv_dump -l build/compile_dump.log > /dev/null
    ./build/simv_dump $(sim_args int8_fast random_00) -l build/dump.log > /dev/null 2>&1
  else
    $VCS $VFLAGS $RTL sim/DUMP_CORE.v -o build/simv_dump -R $(sim_args int8_fast random_00) -l build/dump.log > /dev/null 2>&1
  fi
  if command -v vcd2saif > /dev/null 2>&1; then
    vcd2saif -input build/core.vcd -output syn/core.saif
    echo "syn/core.saif 생성. DC 에서 read_saif 로 사용 (syn/synth.tcl 참조)"
  else
    echo "vcd2saif 가 PATH 에 없음. build/core.vcd 는 생성됨 -> 조교에게 vcd2saif 경로 확인 (없으면 DC 기본 활동률로 전력 추정)"
  fi
fi
