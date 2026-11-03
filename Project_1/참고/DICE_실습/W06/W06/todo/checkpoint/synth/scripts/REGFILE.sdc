# synth.tcl에서 실제 설계 단위가 ns/fF인지 확인한 뒤 적용합니다.
# 교육용 가정: CLK 10ns(100MHz 목표), 이상적 클럭, 단일 코너, 배치 전 추정.
# 데이터·제어·RESET 입력 도착: min 0ns, max 1ns. 입력 slew 0.1ns.
# 출력에 외부 회로가 사용하는 시간: min 0ns, max 1ns.
# 출력당 부하 20fF = 0.020pF. 실제 보드/칩 인터페이스 측정값이 아닙니다.
create_clock -name CLK -period 10.0 [get_ports CLK]
set data_inputs [remove_from_collection [all_inputs] [get_ports CLK]]
set_input_delay -min 0.0 -clock CLK $data_inputs
set_input_delay -max 1.0 -clock CLK $data_inputs
set_input_transition 0.1 $data_inputs
set_output_delay -min 0.0 -clock CLK [all_outputs]
set_output_delay -max 1.0 -clock CLK [all_outputs]
set_load 20.0 [all_outputs]
# RESET을 false path로 숨기지 않습니다. recovery/removal 점검은 별도 보고서에 포함.
# 클럭트리·배선·다중 코너·실제 리셋 해제 동기화는 이번 실습 범위 밖입니다.
