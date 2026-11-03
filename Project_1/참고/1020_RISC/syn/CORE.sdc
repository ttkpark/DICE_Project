# CORE 제약. 지난 학기 수업 RISCVSINGLE.sdc 구조(입출력 지연 = 주기의 40%)를 따르고
# 주기($PERIOD)와 입출력 비율($IO_FRAC)만 synth.tcl 의 변수로 뺐다.
# 조교가 공식 SDC 를 배포하면 이 파일을 그 내용으로 바꾸고 PERIOD 만 맞춘다.   단위: ns / fF
create_clock -name CLOCK -period $PERIOD [get_ports CLK]
set_clock_latency [expr $PERIOD * 0.005] [get_clocks CLOCK]
set_clock_uncertainty -setup [expr $PERIOD * 0.0025] [get_clocks CLOCK]
set_clock_uncertainty -hold  [expr $PERIOD * 0.0005] [get_clocks CLOCK]
set_clock_transition [expr $PERIOD * 0.0025] [get_clocks CLOCK]
set_false_path -from [get_ports RESET] -to [all_registers]
set data_inputs [remove_from_collection [all_inputs] [get_ports {CLK RESET}]]
set_input_delay  [expr $PERIOD * $IO_FRAC] -clock CLOCK $data_inputs
set_input_transition 0.1 $data_inputs
set_output_delay [expr $PERIOD * $IO_FRAC] -clock CLOCK [all_outputs]
set_load 20.0 [all_outputs]
