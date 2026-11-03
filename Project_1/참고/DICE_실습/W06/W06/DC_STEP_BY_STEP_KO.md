# 체크포인트 합성 — 명령어 따라 하기

**방금 실행한 체크포인트가 14/14 PASS이면 시작합니다.**

한 줄씩 입력하고 Enter를 누르세요. **Error / Fatal / FAIL이 나오면 멈추고 조교에게 보여 주세요.** `--More--`에서는 Space를 누릅니다.

## 1. DC 켜기 — Linux 터미널

```bash
cd ~/DICE/W06/todo/checkpoint/synth
dc_shell_queue
```

`dc_shell>`가 나오면 아래로 진행합니다.

## 2. 환경 설정과 RTL 읽기 — DC

```tcl
# 환경 설정
source setup.tcl

# REGFILE 읽기
analyze -format verilog ../rtl/REGFILE.v
elaborate REGFILE
current_design REGFILE
link
check_design

# 단위 확인
report_units
```

`check_design`은 `1`, 단위는 **ns / fF**인지 확인합니다. 다르면 조교에게 알려 주세요.

## 3. 조건 입력 → 합성 → 저장 → 종료 — DC

아래 조건은 그대로 입력합니다. `compile`은 끝날 때까지 기다립니다.

```tcl
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
```

합성 뒤 `check_design`은 `1`, `is_mapped`는 `true`여야 합니다.

## 4. 결과 보기 — Linux 터미널

```bash
cat reports/area.rpt
cat reports/timing_max.rpt
less results/REGFILE_mapped.v
```

면적은 **Total cell area**, 시간 여유는 **slack**에서 찾습니다. slack이 양수면 여유, 음수면 해당 경로의 조건 미달입니다. 넷리스트에서는 셀 연결 하나를 찾고 **q**로 나옵니다. 이 세 가지만 확인하면 끝입니다.

합성은 연습이며 별도 제출은 없습니다. [전체 실습 순서](README_KO.md)
