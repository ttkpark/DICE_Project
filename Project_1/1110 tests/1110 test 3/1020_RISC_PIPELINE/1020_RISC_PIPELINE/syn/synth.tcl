# =============================================================================
# 1020_RISC_PIPELINE CPU(CORE, 5단 파이프라인) 합성 — 보통은 run_synth.sh 가 부른다 (syn/ 폴더에서)
#   합성 대상은 CORE(CONTROLLER 포함)뿐. IMEM/DMEM 은 시뮬레이션 모델이고 SRAM 비용은
#   PROJECT_CONTRACT_KO.md 산식으로 가산한다 (tools/pj1_check.py 가 계산).
#   제약 = R1.3a 공통 SDC 숫자 (CORE.sdc 설명 참조), corner = SS 0.95 V 125 C (setup.tcl)
#
#   PERIOD : 목표 클럭 주기 ns (선언 주파수 = 1000/PERIOD). run_synth.sh 가 period.tcl 에 써 준다.
#            dc_shell 에서 직접 source 할 때는 period.tcl 이 없으면 아래 기본값.
#   GATE_CLK: 1 이면 clock gating (레지스터파일 FF 전력 절감, 면적 약간 증가)
#   결과: reports/P<PERIOD>/{qor,timing_max,timing_min,area,power,power_total,...}.rpt, results/P<PERIOD>/
# =============================================================================
set PERIOD   4.0
set GATE_CLK 0
if {[file exists period.tcl]} { source period.tcl }
set R reports/P$PERIOD
set O results/P$PERIOD

source setup.tcl
file mkdir work $R $O
define_design_lib WORK -path work

analyze -format verilog {../rtl/CONTROLLER.v ../rtl/CORE.v}
elaborate CORE
current_design CORE
link
check_design > $R/check_design.rpt
report_units

source CORE.sdc
report_clock
check_timing

# 전력 활동률: run.sh 를 DUMP=1 로 돌리면 core.saif 가 생긴다 (int8_fast, random_00)
if {[file exists core.saif]} {
    read_saif -input core.saif -instance TB_TOP_DEMO/dut/u_core -verbose
} else {
    puts "synth.tcl: core.saif 없음 -> DC 기본 활동률로 전력 추정 (DUMP=1 bash run.sh 로 생성 가능)"
}

if {$GATE_CLK} {
    set_clock_gating_style -sequential_cell latch -minimum_bitwidth 4
    compile_ultra -no_autoungroup -gate_clock
} else {
    compile_ultra -no_autoungroup
}
check_design
get_attribute [current_design] is_mapped

# R1.3a: 합성·link 가 끝난 뒤, 정상 모드 timing report 직전에 RESET 고정
set_case_analysis 0 [get_ports RESET]

report_qor -significant_digits 4                                                > $R/qor.rpt
report_timing -significant_digits 4 -delay_type max -max_paths 5 -nets -transition_time -capacitance > $R/timing_max.rpt
report_timing -significant_digits 4 -delay_type min -max_paths 3                 > $R/timing_min.rpt
report_constraint -all_violators                           > $R/violators.rpt
report_area -hierarchy                                     > $R/area.rpt
report_power                                               > $R/power_total.rpt
report_power -hierarchy                                    > $R/power.rpt
report_reference                                           > $R/reference.rpt
if {$GATE_CLK} { report_clock_gating                       > $R/clock_gating.rpt }

change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output $O/CORE_mapped.v
write -format ddc -hierarchy -output $O/CORE.ddc
write_sdc $O/CORE.sdc
exit
