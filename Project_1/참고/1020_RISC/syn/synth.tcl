# =============================================================================
# 1020_RISC CPU(CORE) 합성 — dc_shell 프롬프트에서   source synth.tcl   (syn/ 폴더에서)
#   합성 대상은 CORE(CONTROLLER 포함)뿐. IMEM/DMEM 은 시뮬레이션 모델이고 SRAM 비용은
#   PROJECT_CONTRACT_KO.md 산식으로 가산한다 (tools/summarize.py 가 계산).
#
#   바꿀 값
#     PERIOD  : 목표 클럭 주기 ns. 선언 주파수 F_MHZ = 1000/PERIOD.
#               reports/timing_max.rpt 의 slack 이 >= 0 (setup) 이고 timing_min.rpt 도 >= 0 (hold)
#               인 가장 작은 PERIOD 를 찾아 그 값을 run.sh 의 F_MHZ 와 발표에 쓴다.
#     IO_FRAC : 입출력 지연 비율. 조교가 공식 SDC 를 주면 CORE.sdc 를 그 파일로 바꾼다.
#     GATE_CLK: 1 이면 clock gating (레지스터파일 FF 전력 절감, 면적 약간 증가)
# =============================================================================
set PERIOD   5.0
set IO_FRAC  0.4
set GATE_CLK 0

source setup.tcl
file mkdir work results reports
define_design_lib WORK -path work

analyze -format verilog {../rtl/CONTROLLER.v ../rtl/CORE.v}
elaborate CORE
current_design CORE
link
check_design > reports/check_design.rpt
report_units

source CORE.sdc
report_clock
check_timing

# 전력 활동률: run.sh 를 DUMP=1 로 돌리면 core.saif 가 생긴다 (int8_fast, random_00, F_MHZ 기준)
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

report_qor                                                 > reports/qor.rpt
report_timing -delay_type max -max_paths 5 -nets -transition_time -capacitance > reports/timing_max.rpt
report_timing -delay_type min -max_paths 3                 > reports/timing_min.rpt
report_constraint -all_violators                           > reports/violators.rpt
report_area -hierarchy                                     > reports/area.rpt
report_power -hierarchy                                    > reports/power.rpt
report_reference                                           > reports/reference.rpt
if {$GATE_CLK} { report_clock_gating                       > reports/clock_gating.rpt }

change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output results/CORE_mapped.v
write -format ddc -hierarchy -output results/CORE.ddc
write_sdc results/CORE.sdc
exit
