#!/usr/bin/env bash
# CORE 합성.  syn/ 에서:   bash run_synth.sh          결과: reports/*.rpt, dc.log
# DC 실행기 자동 선택: 수업 서버 wrapper dc_shell_queue (slurm 큐) 우선, 없으면 dc_shell. 강제: DC=dc_shell bash run_synth.sh
# wrapper 가 -f 를 받지 않으면 dc_shell_queue 를 띄운 뒤 dc_shell> 프롬프트에   source synth.tcl   을 입력한다.
cd "$(dirname "$0")"
if [ -z "$DC" ]; then
  if   command -v dc_shell_queue > /dev/null 2>&1; then DC=dc_shell_queue
  elif command -v dc_shell       > /dev/null 2>&1; then DC=dc_shell
  else echo "오류: dc_shell_queue / dc_shell 둘 다 없음. 수업 서버에서 실행" >&2; exit 2
  fi
fi
echo "DC 실행기: $DC"
"$DC" -f synth.tcl -output_log_file dc.log
echo "==== 요약 (PERIOD 는 synth.tcl 의 set PERIOD) ===="
grep -E "Critical Path Slack|Total Negative Slack|Combinational Area|Noncombinational Area|Cell Area" reports/qor.rpt
grep -E "slack" reports/timing_max.rpt | head -5
grep -E "slack" reports/timing_min.rpt | head -3
grep -E "Total Dynamic Power|Cell Leakage Power" reports/power.rpt
