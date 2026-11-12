# EE362 Project 1: CPU-only common SDC
# Time unit: ns. Capacitance unit: fF (SAED32 library).
# Example: 250 MHz means a 4.00 ns clock period.
# Change only 4.00 on the create_clock line to your team's period.
# Keep every other number exactly as given.

# 1. Clock
create_clock -name CPU_CLK -period 4.00 [get_ports CLK]
set_clock_uncertainty -setup 0.10 [get_clocks CPU_CLK]
set_clock_uncertainty -hold 0.05 [get_clocks CPU_CLK]
set_clock_transition 0.08 [get_clocks CPU_CLK]

# 2. Data inputs: the fixed TOP has only RESERVED_IN* besides CLK/RESET.
set_input_delay -clock [get_clocks CPU_CLK] -min 1.00 [get_ports {RESERVED_IN*}]
set_input_delay -clock [get_clocks CPU_CLK] -max 1.00 [get_ports {RESERVED_IN*}]
set_input_transition 0.10 [get_ports {RESERVED_IN*}]

# 3. Data outputs: include the fixed outputs and RESERVED_OUT*.
set_output_delay -clock [get_clocks CPU_CLK] -min 1.00 [all_outputs]
set_output_delay -clock [get_clocks CPU_CLK] -max 1.00 [all_outputs]
set_load 20.0 [all_outputs]
set_max_transition 0.25 [all_outputs]

# 4. RESET is synchronous active-high. Do not fix RESET during synthesis:
# doing so may remove the reset circuit. After compile/link, before the
# normal-mode timing report, run this command once in dc_shell:
# set_case_analysis 0 [get_ports RESET]
# Check RESET=1 behavior separately with the official simulation testbench.
