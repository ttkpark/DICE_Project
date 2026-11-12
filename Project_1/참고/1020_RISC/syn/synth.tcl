# =============================================================================
# 1020_RISC CPU(CORE, 단일 사이클) 합성 — 보통은 run_synth.sh 가 부른다 (syn/ 폴더에서)
#   R1.4: 합성 top = TOP (CORE+CONTROLLER 만 포함). IMEM/DMEM 은 TOP 바깥(sim/mem/)의 시뮬레이션 모델이고 SRAM 비용은
#   PROJECT_CONTRACT_KO.md 산식으로 가산한다 (tools/pj1_check.py 가 계산).
#   제약 = R1.4 공통 SDC (TOP.sdc = synth/common.sdc 원문, 주기만 $PERIOD), 합성 명령 = 공식 run_ppa.tcl 과 같은 compile, corner = SS 0.95 V 125 C (setup.tcl)
#
#   PERIOD : 목표 클럭 주기 ns (선언 주파수 = 1000/PERIOD). run_synth.sh 가 period.tcl 에 써 준다.
#            dc_shell 에서 직접 source 할 때는 period.tcl 이 없으면 아래 기본값.
#   DESIGN : TOP(기본, 공식) | CORE(비공식 비교용, CORE.sdc). 보고서는 reports/TOP_P<PERIOD>/ (CORE 는 reports/P<PERIOD>/).
#   GATE_CLK: 1 이면 clock gating (레지스터파일 FF 전력 절감, 면적 약간 증가)
#   결과: reports/P<PERIOD>/{qor,timing_max,timing_min,area,power,power_total,...}.rpt, results/P<PERIOD>/
# =============================================================================
set PERIOD   4.0
set GATE_CLK 0
set DESIGN   TOP
if {[file exists period.tcl]} { source period.tcl }
if {$DESIGN eq "TOP"} { set TAG TOP_P$PERIOD } else { set TAG P$PERIOD }
set R reports/$TAG
set O results/$TAG

source setup.tcl
file mkdir work $R $O
define_design_lib WORK -path work

set RTL {../rtl/CONTROLLER.v ../rtl/CORE.v}
if {$DESIGN eq "TOP"} { lappend RTL ../rtl/TOP.v }   ;# R1.4: TOP 안에 메모리 없음 -> 블랙박스 없이 link 되어야 함
analyze -format verilog $RTL
elaborate $DESIGN
current_design $DESIGN
link
check_design > $R/check_design.rpt
report_units

source $DESIGN.sdc
report_clock
check_timing

# 전력 활동률: run.sh 를 DUMP=1 로 돌리면 core.saif 가 생긴다 (int8_fast, random_00)
if {[file exists core.saif]} {
    read_saif -input core.saif -instance [expr {$DESIGN eq "TOP" ? "TB_TOP_DEMO/dut" : "TB_TOP_DEMO/dut/u_core"}] -verbose
} else {
    puts "synth.tcl: core.saif 없음 -> DC 기본 활동률로 전력 추정 (DUMP=1 bash run.sh 로 생성 가능)"
}

if {$GATE_CLK} {
    set_clock_gating_style -sequential_cell latch -minimum_bitwidth 4
    compile_ultra -no_autoungroup -gate_clock   ;# 비공식 실험 (공식 흐름은 clock gating 없는 compile)
} else {
    compile   ;# 공식 synth/run_ppa.tcl 과 같은 명령 (compile_ultra 로 찾은 주기는 공식 흐름에서 재현되지 않을 수 있음)
}
check_design
get_attribute [current_design] is_mapped

# R1.4: 합성·link 가 끝난 뒤, 정상 모드 timing report 직전에 RESET 고정
set_case_analysis 0 [get_ports RESET]

report_qor                                                 > $R/qor.rpt
report_timing -delay_type max -max_paths 5 -nets -transition_time -capacitance > $R/timing_max.rpt
report_timing -delay_type min -max_paths 3                 > $R/timing_min.rpt
report_constraint -all_violators                           > $R/violators.rpt
check_timing                                               > $R/check_timing.rpt   ;# 제약 안 걸린 경로(INSTR/READDATA 입력 등) 확인용
report_area -hierarchy                                     > $R/area.rpt
report_power                                               > $R/power_total.rpt
report_power -hierarchy                                    > $R/power.rpt
report_reference                                           > $R/reference.rpt
if {$GATE_CLK} { report_clock_gating                       > $R/clock_gating.rpt }

change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output $O/${DESIGN}_mapped.v
write -format ddc -hierarchy -output $O/$DESIGN.ddc
write_sdc $O/$DESIGN.sdc
exit
