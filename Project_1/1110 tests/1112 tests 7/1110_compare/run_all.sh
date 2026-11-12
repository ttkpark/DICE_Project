#!/usr/bin/env bash
# =============================================================================
# 1110 비교 실험 일괄 실행 (수업 서버용: vcs_queue, vcd2saif, dc_shell_queue, python3)
#
#   사용법   bash run_all.sh 2>&1 | tee run_all.log
#            (오래 걸린다. 접속이 끊겨도 돌게 하려면:  nohup bash run_all.sh > run_all.log 2>&1 &)
#
#   실험 폴더 하나마다 아래 4단계를 차례로 한다.
#     1단계  계약 검사      tools/check_release.py       (TOP 포트, 합성 목록, 공통 SDC)
#     2단계  주기 탐색      ../tools/sweep_timing.tcl    (후보 주기마다 합성 + STA, 전력 없음)
#     3단계  주기 선택      setup·hold slack 이 둘 다 0 이상인 가장 짧은 주기를 synth/common.sdc 에 기록
#     4단계  공식 측정      프로그램마다 run_flow.py sim -> run_flow.py ppa   (run_sim.sh / run_ppa.sh 와 같은 명령)
#            4단계가 timing 에서 떨어지면 그 다음으로 짧은 통과 주기로 다시 한다.
#   끝나면   tools/summary.py 가 세 폴더 결과를 results/summary.md, results/summary.csv 로 모은다.
#
#   결과 위치
#     <실험>/results/sweep.csv                   주기 탐색 표 (slack 소수 4자리)
#     <실험>/reports/sweep/                      주기별 setup/hold 경로 보고서
#     <실험>/comparisons/<프로그램>_P<주기>/     공식 측정 결과 (ppa_summary.json, reports/, DC 로그)
#     results/summary.md                         세 실험 비교표
# =============================================================================
set -u
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"

# ----------------------------------------------------------------------------
# 설정: 여기만 고치면 된다
# ----------------------------------------------------------------------------

# 돌릴 실험 폴더 (순서대로)
EXPERIMENTS="1110_single_cycle 1110_pipeline_ID 1110_pipeline_EX"

# 측정할 프로그램 (실험 폴더 기준 경로)
PROGRAMS="programs/int8_fast.hex programs/int8_fastv2.hex programs/int8_opt64.hex programs/int8_opt64v2.hex"
# 배포 기준본까지 재려면 아래 줄의 주석을 푼다 (case 당 cycle 이 10배 이상이라 VCD 가 크고 오래 걸린다).
# PROGRAMS="baseline_int8_fc_slow.hex $PROGRAMS"

# 실험별 후보 주기 [ns].
#   - 반드시 소수 둘째 자리까지 쓴다 (예: 1.70). TB 시간 단위가 1 fs 라서 반주기가 fs 로 나누어떨어져야
#     공식 flow 의 "cycle x 주기 = 실행 구간" 검사를 통과한다. 0.01 ns 단위는 항상 안전하다.
#   - 합성 결과는 주기에 대해 단조롭지 않다 (2.00 은 되고 2.05 는 안 될 수 있다). 그래서 전부 돌려 본다.
candidate_periods() {
    case "$1" in
        1110_single_cycle) echo "3.82" ;;
        1110_pipeline_ID)  echo "2.36" ;;
        1110_pipeline_EX)  echo "1.62" ;;
    *)                 echo "4.00" ;;
    esac
}

# ----------------------------------------------------------------------------
# 단계별 함수 (모두 실험 폴더 안에서 실행된다)
# ----------------------------------------------------------------------------

say() { echo; echo "==== [$EXP] $*"; }

# 2단계: 후보 주기를 한 번의 DC 실행으로 모두 합성한다.
sweep_periods() {
    local periods="$1" p
    for p in $periods; do
        [[ "$p" =~ ^[0-9]+\.[0-9][0-9]$ ]] || { echo "주기는 소수 둘째 자리까지 써야 한다: $p"; return 1; }
    done
    mkdir -p build logs results
    rm -f results/sweep.csv
    echo "set P1_SWEEP {$periods}" > build/sweep_periods.tcl
    dc_shell_queue -f ../tools/sweep_timing.tcl > logs/sweep.log 2>&1
    grep -q "P1_SWEEP_COMPLETE" logs/sweep.log || { echo "주기 탐색이 끝까지 돌지 않았다: $EXP/logs/sweep.log"; return 1; }
    column -s, -t results/sweep.csv 2> /dev/null || cat results/sweep.csv
}

# 3단계: sweep.csv 에서 통과(pass=1)한 주기를 짧은 것부터 나열한다.
passing_periods() {
    awk -F, 'NR > 1 && $5 == 1 { print $1 }' results/sweep.csv | sort -n
}

# 3단계: 공통 SDC 에서 주기 숫자 한 곳만 바꾼다 (팀이 바꿔도 되는 유일한 값).
set_period() {
    sed -i -E "s/^(create_clock -name CPU_CLK -period )[0-9.]+/\1$1/" synth/common.sdc
    grep -n "^create_clock" synth/common.sdc
}

# 4단계: 지금 SDC 주기로 모든 프로그램을 공식 flow 로 잰다. 하나라도 실패하면 1 을 돌려준다.
measure_all_programs() {
    local period="$1" program name out
    for program in $PROGRAMS; do
        name="$(basename "$program" .hex)"
        out="comparisons/${name}_P${period}"
        say "공식 측정: $name @ ${period} ns"

        python3 tools/run_flow.py sim --program "$program" || return 1   # 기능 16 case + activity (VCS)
        python3 tools/run_flow.py ppa                      || return 1   # 합성 + STA + case별 전력 (DC)

        mkdir -p "$out"
        cp results/ppa_summary.json results/ppa_status.json results/simulation_manifest.json "$out/"
        cp logs/dc_ppa.log "$out/"
        cp -r reports "$out/reports"
        rm -rf "$out/reports/sweep"
    done
}

# 실험 폴더 하나 전체
run_experiment() {
    local period

    say "1단계: 계약 검사"
    python3 tools/check_release.py || return 1

    say "2단계: 주기 탐색  ($(candidate_periods "$EXP"))"
    sweep_periods "$(candidate_periods "$EXP")" || return 1

    # 이전 실행의 측정 결과가 새 결과와 섞이지 않게 옮겨 둔다.
    [ -d comparisons ] && mv comparisons "comparisons.prev.$(date +%m%d_%H%M%S)"

    for period in $(passing_periods); do
        say "3단계: 주기 선택 -> ${period} ns"
        set_period "$period"
        say "4단계: 공식 측정 시작"
        if measure_all_programs "$period"; then
            return 0
        fi
        echo "[$EXP] ${period} ns 에서 공식 측정 실패 -> 다음 통과 주기로 다시 한다"
        rm -rf comparisons
    done
    echo "[$EXP] 측정에 성공한 주기가 없다 (후보 주기를 늘리거나 logs/ 를 확인)"
    return 1
}

# ----------------------------------------------------------------------------
# 본문
# ----------------------------------------------------------------------------

for tool in python3 vcs_queue vcd2saif dc_shell_queue; do
    command -v "$tool" > /dev/null || { echo "필요한 명령이 없다: $tool (수업 서버에서 실행)"; exit 2; }
done

STATUS=""
for EXP in $EXPERIMENTS; do
    echo
    echo "############################################################"
    echo "#  $EXP    $(date '+%Y-%m-%d %H:%M:%S')"
    echo "############################################################"
    if (cd "$HERE/$EXP" && run_experiment); then
        STATUS="$STATUS\n  PASS  $EXP"
    else
        STATUS="$STATUS\n  FAIL  $EXP"
    fi
done

echo
echo "############################################################"
echo "#  요약    $(date '+%Y-%m-%d %H:%M:%S')"
echo "############################################################"
python3 "$HERE/tools/summary.py"
echo
echo -e "실험별 실행 결과:$STATUS"
