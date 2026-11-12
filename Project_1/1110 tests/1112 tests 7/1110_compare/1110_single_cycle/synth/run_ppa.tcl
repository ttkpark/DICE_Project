# Run from package root: dc_shell_queue -f synth/run_ppa.tcl
# The Python driver first checks the source/clock/activity fingerprint.
# Compile once. Every per-case power report uses this same mapped CPU.
file mkdir build/dc_work results reports
source synth/library_setup.tcl
define_design_lib WORK -path build/dc_work
saif_map -start

# Only CPU RTL listed in rtl.f. No TB, IMEM, DMEM, readmemh interpreter.
set p1_file [open synth/rtl.f r]
set p1_rtl {}
while {[gets $p1_file p1_line] >= 0} {
    set p1_line [string trim [lindex [split $p1_line #] 0]]
    if {$p1_line ne ""} {lappend p1_rtl $p1_line}
}
close $p1_file
analyze -format verilog $p1_rtl
elaborate TOP
current_design TOP
if {![link]} {error "P1: unresolved CPU module/library reference"}
check_design > reports/check_design_before.rpt
report_units > reports/units.rpt
source synth/common.sdc

# Do not set_case_analysis RESET before compile: keep the reset circuit.
compile
check_design > reports/check_design_after.rpt
if {![get_attribute [current_design] is_mapped]} {error "P1: CPU is not fully mapped"}
if {[sizeof_collection [get_designs -quiet {IMEM DMEM TB_TOP MEMORY_POWER}]] != 0} {
    error "P1: simulation design included in CPU synthesis"
}
write -format verilog -hierarchy -output results/TOP_mapped.v
write -format ddc -hierarchy -output results/TOP_mapped.ddc
report_area > reports/cpu_area.rpt

# Normal-mode STA only, after mapped CPU has been saved.
set_case_analysis 0 [get_ports RESET]
check_timing > reports/check_timing.rpt
report_clock > reports/clock.rpt
report_timing -delay_type max -max_paths 10 > reports/setup.rpt
report_timing -delay_type min -max_paths 10 > reports/hold.rpt
report_constraint -all_violators > reports/constraints.rpt
write_sdc results/TOP_normal_mode.sdc

set p1_setup [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
set p1_hold [get_timing_paths -delay_type min -max_paths 1 -nworst 1]
if {[sizeof_collection $p1_setup] == 0 || [sizeof_collection $p1_hold] == 0} {
    error "P1: no setup/hold path found; do not treat an empty timing report as PASS"
}
set p1_setup_slack [get_attribute $p1_setup slack]
set p1_hold_slack [get_attribute $p1_hold slack]
set p1_timing_pass [expr {$p1_setup_slack >= 0.0 && $p1_hold_slack >= 0.0}]
set p1_status [open results/ppa_status.json w]
puts $p1_status "{\"timing_pass\":$p1_timing_pass,\"setup_slack_ns\":$p1_setup_slack,\"hold_slack_ns\":$p1_hold_slack}"
close $p1_status

# RTL SAIF -> mapped CPU correspondence recorded by saif_map in this session.
# No recompile between cases. No vectorless fallback when SAIF is missing.
source synth/case_list.tcl
foreach p1_case $P1_CASES {
    file mkdir reports/$p1_case
    if {![file isfile build/$p1_case.saif]} {error "P1: missing case SAIF $p1_case"}
    reset_switching_activity
    if {![read_saif -input build/$p1_case.saif -instance_name TB_TOP/dut -auto_map_names -verbose]} {
        error "P1: SAIF annotation failed for $p1_case"
    }
    report_saif -hierarchy > reports/$p1_case/annotation.rpt
    report_power > reports/$p1_case/power.rpt
}
if {!$p1_timing_pass} {error "P1: setup/hold failed; inspect reports before PPA comparison"}
puts "P1_PPA_COMPLETE"
exit
