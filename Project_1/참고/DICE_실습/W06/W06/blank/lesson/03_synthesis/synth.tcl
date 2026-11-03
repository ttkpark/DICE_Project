# DC 프롬프트에 아래 명령을 한 줄씩 입력합니다.
# 환경 설정
source setup.tcl

# REGFILE 읽기
analyze -format verilog REGFILE.v
elaborate REGFILE
current_design REGFILE
link
check_design

# 단위 확인
report_units


# 클럭 10 ns, 입출력 조건
create_clock -name CLK -period 10.0 [get_ports CLK]
set data_inputs [remove_from_collection [all_inputs] [get_ports CLK]]
set_input_delay -min 0.0 -clock CLK $data_inputs
set_input_delay -max 1.0 -clock CLK $data_inputs
set_input_transition 0.1 $data_inputs
set_output_delay -min 0.0 -clock CLK [all_outputs]
set_output_delay -max 1.0 -clock CLK [all_outputs]
set_load 20.0 [all_outputs]
report_clock
check_timing

# 합성
compile
check_design
get_attribute [current_design] is_mapped

# 결과 저장
write -format verilog -hierarchy -output results/REGFILE_mapped.v
write -format ddc -hierarchy -output results/REGFILE.ddc
write_sdc results/REGFILE.sdc
report_area > reports/area.rpt
report_timing -delay_type max -max_paths 1 > reports/timing_max.rpt

# DC 종료
exit
