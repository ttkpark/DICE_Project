# EE362 Project 1 R1.4 CPU-only common SDC. Units: ns / fF.
# Only the period number 4.00 may be changed by a team.
# 100MHz=10.00ns, 200MHz=5.00ns, 250MHz=4.00ns.
create_clock -name CPU_CLK -period 2.36 [get_ports CLK]
set_clock_uncertainty -setup 0.10 [get_clocks CPU_CLK]
set_clock_uncertainty -hold 0.05 [get_clocks CPU_CLK]
set_clock_transition 0.08 [get_clocks CPU_CLK]

# R1.4: instruction/data inputs and all 20 reserved input buses.
set_input_delay -clock [get_clocks CPU_CLK] -min 1.00 [get_ports {INSTR READDATA RESERVED_IN*}]
set_input_delay -clock [get_clocks CPU_CLK] -max 1.00 [get_ports {INSTR READDATA RESERVED_IN*}]
set_input_transition 0.10 [get_ports {INSTR READDATA RESERVED_IN*}]

# CPU outputs and reserved output buses. IMEM/DMEM are not in TOP.
set_output_delay -clock [get_clocks CPU_CLK] -min 1.00 [all_outputs]
set_output_delay -clock [get_clocks CPU_CLK] -max 1.00 [all_outputs]
set_load 20.0 [all_outputs]
set_max_transition 0.25 [all_outputs]

# RESET: synchronous active-high. Do NOT case-analyze before compile.
# After compile, run: set_case_analysis 0 [get_ports RESET]
# Reset behavior is checked separately by functional simulation.
