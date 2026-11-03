# DC 안에서 아래 명령을 한 줄씩 입력합니다. source synth.tcl로 일괄 실행하지 않습니다.

# 작업 폴더와 라이브러리 설정
source setup.tcl

# 제어기와 관찰용 레지스터 읽기
analyze -format verilog {../rtl/CONTROLLER.v CONTROL_TIMING.v}

# 최상위 회로 구성
elaborate CONTROL_TIMING

# 작업 대상 선택
current_design CONTROL_TIMING

# 모듈과 라이브러리 연결
link

# 연결 오류 확인
check_design

# 단위 확인: ns / fF 전제
report_units

# 10ns 클럭 지정
create_clock -name CLK -period 10.0 [get_ports CLK]

# 클럭을 제외한 데이터 입력 선택
set data_inputs [remove_from_collection [all_inputs] [get_ports CLK]]

# 입력 최소 지연 지정
set_input_delay -min 0.0 -clock CLK $data_inputs

# 입력 최대 지연 지정
set_input_delay -max 1.0 -clock CLK $data_inputs

# 입력 전이시간 지정
set_input_transition 0.1 $data_inputs

# 출력 최소 지연 지정
set_output_delay -min 0.0 -clock CLK [all_outputs]

# 출력 최대 지연 지정
set_output_delay -max 1.0 -clock CLK [all_outputs]

set_case_analysis 1 [get_ports RESET]

# 출력 부하 지정
set_load 20.0 [all_outputs]

# 클럭 확인
report_clock

# 제약 누락 확인. 경고는 조교 확인 후 진행
check_timing

# 표준셀로 합성
compile

# 합성 후 회로 검사
check_design

# true 여부 확인
get_attribute [current_design] is_mapped

# 같은 mapped netlist 보관
write -format verilog -hierarchy -output results/CONTROL_TIMING_mapped.v

# 면적 저장
report_area > reports/area.rpt

# 10ns setup 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type max -max_paths 1 > reports/setup_10ns.rpt

# 10ns hold 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type min -max_paths 1 > reports/hold_10ns.rpt

# 기존 CLK 주기만 5ns로 대체. 재합성하지 않음
create_clock -name CLK -period 5.0 [get_ports CLK]

# 주기 변경 확인
report_clock

# 같은 회로의 setup 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type max -max_paths 1 > reports/setup_5ns.rpt

# 같은 회로의 hold 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type min -max_paths 1 > reports/hold_5ns.rpt

# 5ns 제약 보관
write_sdc results/CONTROL_TIMING_5ns.sdc

# Linux로 복귀
exit
