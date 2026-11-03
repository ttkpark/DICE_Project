#!/bin/sh
# usage: sh build.sh 25000000   -> output_files/W10_DE2_<N>.sof + logs/<N>_*.rpt
N=$1; Q=/c/altera/13.0sp1/quartus/bin64
cd "$(dirname "$0")" && mkdir -p logs
sed -i "s/^set_parameter -name HALF_PERIOD_CYCLES .*/set_parameter -name HALF_PERIOD_CYCLES $N/" W10_DE2.qsf
"$Q/quartus_sh" --flow compile W10_DE2 > logs/${N}_flow.log 2>&1; echo "exit=$?"
cp output_files/W10_DE2.sof output_files/W10_DE2_$N.sof
for r in flow map sta; do cp output_files/W10_DE2.$r.rpt logs/${N}_$r.rpt; done
