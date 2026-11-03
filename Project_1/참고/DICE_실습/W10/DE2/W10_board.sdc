# 50 MHz physical clock
create_clock -name clk50 -period 20.000 -waveform {0.000 10.000} [get_ports {CLOCK_50}]
# TimeQuest derives clock uncertainty
derive_clock_uncertainty
# Button -> first synchronizer FF only
set_false_path -from [get_ports {KEY[0]}] -to [get_registers {*key_meta}]
# Human-visible LED output
set_false_path -to [get_ports {LEDR[0]}]
