# =============================================================================
# 주기 탐색 (timing 만). run_all.sh 가 각 실험 폴더 루트에서 부른다:
#     dc_shell_queue -f ../tools/sweep_timing.tcl
#
# 공식 synth/run_ppa.tcl 과 같은 순서·같은 명령으로 합성한다
#   (rtl.f 의 CPU RTL -> elaborate TOP -> common.sdc -> compile -> RESET=0 -> STA).
# 다른 점은 하나: common.sdc 의 create_clock 주기 숫자를 후보 값으로 바꿔 가며 반복한다.
# SAIF·전력은 다루지 않는다. 전력과 최종 판정은 공식 run_ppa.sh 가 낸다.
#
# 입력 : build/sweep_periods.tcl   (run_all.sh 가 씀)   set P1_SWEEP {4.00 3.90 ...}
# 출력 : results/sweep.csv         period_ns,setup_slack_ns,hold_slack_ns,cpu_cell_area_um2,pass
#        reports/sweep/setup_<주기>.rpt, hold_<주기>.rpt   (소수 4자리)
# =============================================================================
file mkdir build/dc_work results reports/sweep
source synth/library_setup.tcl
define_design_lib WORK -path build/dc_work
source build/sweep_periods.tcl

# CPU RTL 목록: run_ppa.tcl 과 같은 방식으로 synth/rtl.f 를 읽는다.
set p1_file [open synth/rtl.f r]
set p1_rtl {}
while {[gets $p1_file p1_line] >= 0} {
    set p1_line [string trim [lindex [split $p1_line #] 0]]
    if {$p1_line ne ""} {lappend p1_rtl $p1_line}
}
close $p1_file
analyze -format verilog $p1_rtl

# 공통 SDC 원문. 아래에서 주기 숫자 한 곳만 바꿔 쓴다.
set p1_file [open synth/common.sdc r]
set p1_sdc [read $p1_file]
close $p1_file

set p1_csv [open results/sweep.csv w]
puts $p1_csv "period_ns,setup_slack_ns,hold_slack_ns,cpu_cell_area_um2,pass"

foreach p1_period $P1_SWEEP {
    puts "P1_SWEEP period $p1_period ns"
    remove_design -all
    elaborate TOP
    current_design TOP
    if {![link]} {error "P1: unresolved CPU module/library reference"}

    if {[regsub {(create_clock -name CPU_CLK -period )[0-9.]+} $p1_sdc "\\1$p1_period" p1_sdc_now] != 1} {
        error "P1: create_clock line not found in synth/common.sdc"
    }
    set p1_file [open build/sweep_common.sdc w]
    puts $p1_file $p1_sdc_now
    close $p1_file
    source build/sweep_common.sdc

    compile
    set_case_analysis 0 [get_ports RESET]

    report_timing -delay_type max -max_paths 3 -significant_digits 4 > reports/sweep/setup_$p1_period.rpt
    report_timing -delay_type min -max_paths 3 -significant_digits 4 > reports/sweep/hold_$p1_period.rpt
    set p1_setup [get_attribute [get_timing_paths -delay_type max -max_paths 1 -nworst 1] slack]
    set p1_hold  [get_attribute [get_timing_paths -delay_type min -max_paths 1 -nworst 1] slack]
    redirect -variable p1_area_rpt {report_area}
    if {![regexp {Total cell area:\s*([\d.eE+\-]+)} $p1_area_rpt -> p1_area]} {error "P1: no cell area in report_area"}

    # pass 는 반올림 전 값으로 판정한다 (공식 flow 와 같은 기준: 둘 다 0 이상).
    set p1_pass [expr {$p1_setup >= 0.0 && $p1_hold >= 0.0}]
    puts $p1_csv [format "%s,%.4f,%.4f,%.2f,%d" $p1_period $p1_setup $p1_hold $p1_area $p1_pass]
    flush $p1_csv
}
close $p1_csv
puts "P1_SWEEP_COMPLETE"
exit
