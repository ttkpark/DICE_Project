#!/usr/bin/env bash
# CORE 합성 + 주기 탐색.  syn/ 에서:   bash run_synth.sh [주기ns ...]          기본 4.0
#   예) bash run_synth.sh 8 6 5 4 3.5 3     -> 주기마다 합성, reports/P<주기>/ 에 보고서, 끝에 slack 표
#   setup·hold slack 이 둘 다 >= 0 인 최소 주기가 선언 주파수 후보.
#   그 다음 패키지 루트에서  python3 tools/pj1_check.py  를 다시 돌리면 그 주기로 T/A/P 를 계산한다 (재시뮬 불필요).
# DC 실행기 자동 선택: 수업 서버 wrapper dc_shell_queue (slurm 큐) 우선, 없으면 dc_shell. 강제: DC=dc_shell bash run_synth.sh
# wrapper 가 -f 를 받지 않으면: echo "set PERIOD 4.0" > period.tcl 후 dc_shell_queue 를 띄우고 dc_shell> 에서  source synth.tcl
cd "$(dirname "$0")"
if [ -z "$DC" ]; then
  if   command -v dc_shell_queue > /dev/null 2>&1; then DC=dc_shell_queue
  elif command -v dc_shell       > /dev/null 2>&1; then DC=dc_shell
  else echo "오류: dc_shell_queue / dc_shell 둘 다 없음. 수업 서버에서 실행" >&2; exit 2
  fi
fi
echo "DC 실행기: $DC"
PERIODS=${*:-4.0}
for P in $PERIODS; do
  echo "set PERIOD $P" > period.tcl
  echo "==== PERIOD $P ns ($(awk "BEGIN{printf \"%.1f\", 1000/$P}") MHz) 합성 중 ... (dc_P$P.log)"
  "$DC" -f synth.tcl -output_log_file dc_P$P.log > /dev/null
done
rm -f period.tcl
echo
printf "%-8s %-9s %-11s %-11s %-12s %s\n" period MHz setup_slack hold_slack "area_um2" power
for P in $PERIODS; do
  R=reports/P$P
  [ -f $R/qor.rpt ] || { echo "P$P: 보고서 없음 (dc_P$P.log 확인)"; continue; }
  printf "%-8s %-9s %-11s %-11s %-12s %s\n" "$P" "$(awk "BEGIN{printf \"%.1f\", 1000/$P}")" \
    "$(grep -m1 -E '^ *slack' $R/timing_max.rpt | awk '{print $NF}')" \
    "$(grep -m1 -E '^ *slack' $R/timing_min.rpt | awk '{print $NF}')" \
    "$(grep -m1 'Cell Area:' $R/qor.rpt | awk '{print $NF}')" \
    "$(grep -E 'Total Dynamic Power|Cell Leakage Power' $R/power_total.rpt | sed 's/  */ /g' | tr '\n' ' ')"
done
