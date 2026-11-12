# R1.3a 공통 SDC (Project1_INT8_CPU_ONLY_20261023.sdc, 같은 폴더에 원문) 의 숫자를 CORE 포트에 그대로 적용한 판.
#   공식 SDC 는 TOP 기준(입력 delay 대상 RESERVED_IN*) 인데 TOP 안의 IMEM/DMEM 은 시뮬레이션 모델이라 합성하지 않고
#   CORE 를 합성한다 (TOP 합성 시 메모리 처리 방법은 조교 확인 중, HANDOVER §8-1).
#   원문과 다른 점은 입력 delay 대상 하나: RESERVED_IN* 대신 CORE 데이터 입력 INSTR, READDATA
#   -> CORE 바깥의 IMEM/DMEM 이 입력·출력 쪽에서 각각 1.00 ns 를 쓴다고 보는 셈. 단일 사이클/파이프라인을 같은 조건으로 비교.
#   주기는 $PERIOD (run_synth.sh 인자). 나머지 숫자는 원문 그대로 - 바꾸지 말 것.
#   RESET 은 여기서 고정하지 않는다. synth.tcl 이 compile 뒤 timing report 직전에 set_case_analysis 0 을 건다 (R1.3a 순서).

# 1. Clock
create_clock -name CPU_CLK -period $PERIOD [get_ports CLK]
set_clock_uncertainty -setup 0.10 [get_clocks CPU_CLK]
set_clock_uncertainty -hold 0.05 [get_clocks CPU_CLK]
set_clock_transition 0.08 [get_clocks CPU_CLK]

# 2. Data inputs (CORE: INSTR, READDATA)
set_input_delay -clock [get_clocks CPU_CLK] -min 1.00 [get_ports {INSTR* READDATA*}]
set_input_delay -clock [get_clocks CPU_CLK] -max 1.00 [get_ports {INSTR* READDATA*}]
set_input_transition 0.10 [get_ports {INSTR* READDATA*}]

# 3. Data outputs
set_output_delay -clock [get_clocks CPU_CLK] -min 1.00 [all_outputs]
set_output_delay -clock [get_clocks CPU_CLK] -max 1.00 [all_outputs]
set_load 20.0 [all_outputs]
set_max_transition 0.25 [all_outputs]
