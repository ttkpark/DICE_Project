# Project 1 공통 SDC 사용법

`Project1_INT8_CPU_ONLY_20261023.sdc`에는 변수·조건문·계산식이 없습니다. 위에서 아래로 clock, 입력, 출력을 차례대로 읽으면 됩니다. 00·01분반은 같은 파일을 사용합니다.

## 학생이 바꿀 숫자: clock period 한 곳

SDC의 `create_clock -name CPU_CLK -period 4.00 [get_ports CLK]`에서 **`4.00`만** 팀의 목표 주기에 맞게 바꿉니다. 단위는 ns입니다. 예를 들어 100 MHz는 `10.00`, 200 MHz는 `5.00`, 250 MHz는 `4.00`입니다. 관계식은 `주기(ns) = 1000 / 주파수(MHz)`입니다. 나머지 숫자는 모두 공통 채점값이므로 바꾸지 않습니다.

| SDC 명령 | 고정값 | 뜻 |
|---|---:|---|
| `set_clock_uncertainty -setup` | 0.10 ns | setup 여유에서 차감 |
| `set_clock_uncertainty -hold` | 0.05 ns | hold 검사에 적용 |
| `set_clock_transition` | 0.08 ns | clock 에지의 전환 시간 |
| `set_input_delay -min`, `-max` | 각각 1.00 ns | 외부에서 입력이 도착하는 시간 |
| `set_input_transition` | 0.10 ns | 입력 신호의 전환 시간 |
| `set_output_delay -min`, `-max` | 각각 1.00 ns | 출력에 남겨 둘 외부 시간 |
| `set_load` | 20 fF | 출력 부하 |
| `set_max_transition` | 0.25 ns | 출력 최대 전환 시간 |

입력 제약의 `RESERVED_IN*`은 고정 TOP의 20개 예약 입력을 뜻합니다. `CLK`는 clock으로 따로 지정하고 `RESET`에는 입력 delay를 주지 않습니다. `[all_outputs]`는 고정 TOP의 모든 출력과 예약 출력을 포함합니다. 예약 입력은 공식 TB에서 모두 0으로 구동하며, 예약 출력은 연결하지 않습니다.

## 실행 순서

1. 팀의 목표 주기를 정하고 SDC의 `-period 4.00` 숫자 한 곳만 수정합니다.
2. CPU TOP 합성·compile 전에 다음 명령을 실행합니다.

   ```tcl
   source Project1_INT8_CPU_ONLY_20261023.sdc
   ```

3. 공통 실행 절차에 따라 합성과 link를 끝냅니다. 합성 중에는 RESET을 0으로 고정하지 않습니다.
4. **합성·link가 끝난 뒤**, 정상 동작 모드의 timing report를 만들기 직전에 다음 두 명령을 차례로 실행합니다.

   ```tcl
   set_case_analysis 0 [get_ports RESET]
   report_timing
   ```

`set_case_analysis`를 합성 전에 실행하면 reset 회로가 최적화되어 없어질 수 있습니다. RESET은 동기 active-high입니다. 즉 clock 상승 에지에서 `RESET=1`이면 초기 상태로 들어가야 합니다. RESET 동작은 정상 모드 STA와 별개로 공식 시뮬레이션에서 검사합니다.

PPA의 CPU timing은 SAED32 RVT SS, 0.95 V, 125 °C에서 비교합니다. SRAM 비용은 발표자료의 별도 산식을 따릅니다.
