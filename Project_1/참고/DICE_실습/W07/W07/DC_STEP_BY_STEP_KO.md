# W07 — DC 명령을 한 줄씩 실행하기

정답 회로로 타이밍을 관찰합니다. **Linux 명령은 터미널에, Tcl 명령은 `dc_shell>` 안에** 입력합니다. 프롬프트 글자는 복사하지 않습니다.

한 줄 입력 → Enter → 출력 확인 → 다음 줄 순서입니다. `compile`은 끝날 때까지 기다립니다. `--More--`가 나오면 Space를 누릅니다. Error/Fatal, link/check_design 실패, check_timing 경고가 나오면 조교와 확인한 뒤 진행합니다.

`source setup.tcl`은 라이브러리와 작업 폴더만 준비합니다. 같은 30개 명령이 각 버전의 `synth/synth.tcl`에도 있습니다.

## 실행 순서

처음에는 정답 회로로 진행. TODO 완성 후 todo/synth에서 같은 절차 반복 가능.

```bash
# 정답의 합성 폴더 이동
cd ~/DICE/W07/answer/synth
# DC 대화형 셸 시작
dc_shell_queue
```

아래는 **DC 안에서** 한 줄씩 실행. source setup.tcl은 초기 설정만 수행하며 합성을 자동 실행하지 않음.

### 01. 작업 폴더와 라이브러리 설정

```tcl
# 작업 폴더와 라이브러리 설정
source setup.tcl
```

### 02. 제어기와 관찰용 레지스터 읽기

```tcl
# 제어기와 관찰용 레지스터 읽기
analyze -format verilog {../rtl/CONTROLLER.v CONTROL_TIMING.v}
```

### 03. 최상위 회로 구성

```tcl
# 최상위 회로 구성
elaborate CONTROL_TIMING
```

### 04. 작업 대상 선택

```tcl
# 작업 대상 선택
current_design CONTROL_TIMING
```

### 05. 모듈과 라이브러리 연결

```tcl
# 모듈과 라이브러리 연결
link
```

### 06. 연결 오류 확인

```tcl
# 연결 오류 확인
check_design
```

### 07. 단위 확인: ns / fF 전제

```tcl
# 단위 확인: ns / fF 전제
report_units
```

### 08. 10ns 클럭 지정

```tcl
# 10ns 클럭 지정
create_clock -name CLK -period 10.0 [get_ports CLK]
```

### 09. 클럭을 제외한 데이터 입력 선택

```tcl
# 클럭을 제외한 데이터 입력 선택
set data_inputs [remove_from_collection [all_inputs] [get_ports CLK]]
```

### 10. 입력 최소 지연 지정

```tcl
# 입력 최소 지연 지정
set_input_delay -min 0.0 -clock CLK $data_inputs
```

### 11. 입력 최대 지연 지정

```tcl
# 입력 최대 지연 지정
set_input_delay -max 1.0 -clock CLK $data_inputs
```

### 12. 입력 전이시간 지정

```tcl
# 입력 전이시간 지정
set_input_transition 0.1 $data_inputs
```

### 13. 출력 최소 지연 지정

```tcl
# 출력 최소 지연 지정
set_output_delay -min 0.0 -clock CLK [all_outputs]
```

### 14. 출력 최대 지연 지정

```tcl
# 출력 최대 지연 지정
set_output_delay -max 1.0 -clock CLK [all_outputs]
```

### 15. 출력 부하 지정

```tcl
# 출력 부하 지정
set_load 20.0 [all_outputs]
```

### 16. 클럭 확인

```tcl
# 클럭 확인
report_clock
```

### 17. 제약 누락 확인. 경고는 조교 확인 후 진행

```tcl
# 제약 누락 확인. 경고는 조교 확인 후 진행
check_timing
```

### 18. 표준셀로 합성

```tcl
# 표준셀로 합성
compile
```

### 19. 합성 후 회로 검사

```tcl
# 합성 후 회로 검사
check_design
```

### 20. true 여부 확인

```tcl
# true 여부 확인
get_attribute [current_design] is_mapped
```

### 21. 같은 mapped netlist 보관

```tcl
# 같은 mapped netlist 보관
write -format verilog -hierarchy -output results/CONTROL_TIMING_mapped.v
```

### 22. 면적 저장

```tcl
# 면적 저장
report_area > reports/area.rpt
```

### 23. 10ns setup 보고서 저장

```tcl
# 10ns setup 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type max -max_paths 1 > reports/setup_10ns.rpt
```

### 24. 10ns hold 보고서 저장

```tcl
# 10ns hold 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type min -max_paths 1 > reports/hold_10ns.rpt
```

### 25. 기존 CLK 주기만 5ns로 대체. 재합성하지 않음

```tcl
# 기존 CLK 주기만 5ns로 대체. 재합성하지 않음
create_clock -name CLK -period 5.0 [get_ports CLK]
```

### 26. 주기 변경 확인

```tcl
# 주기 변경 확인
report_clock
```

### 27. 같은 회로의 setup 보고서 저장

```tcl
# 같은 회로의 setup 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type max -max_paths 1 > reports/setup_5ns.rpt
```

### 28. 같은 회로의 hold 보고서 저장

```tcl
# 같은 회로의 hold 보고서 저장
report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] -delay_type min -max_paths 1 > reports/hold_5ns.rpt
```

### 29. 5ns 제약 보관

```tcl
# 5ns 제약 보관
write_sdc results/CONTROL_TIMING_5ns.sdc
```

### 30. Linux로 복귀

```tcl
# Linux로 복귀
exit
```

이후 **Linux에서** 보고서 확인:

```bash
# 10ns setup
cat reports/setup_10ns.rpt
# 5ns setup
cat reports/setup_5ns.rpt
# 10ns hold
cat reports/hold_10ns.rpt
# 5ns hold
cat reports/hold_5ns.rpt
```



## 보고서 읽기와 기록지

- report_timing -delay_type max: setup 검사. slack = required − arrival.
- report_timing -delay_type min: hold 검사. slack = arrival − required.
- slack < 0이면 violation. 0 이상이면 **그 분석 조건에서 그 경로**가 요구 충족.
- register-to-register 경로만 선택. 실제 Startpoint, Endpoint, Path Type(max/min), Path Group(CLK)을 확인. 경로 없음/no paths는 성공이 아님.
- 10ns→5ns 비교에서 재compile 금지. 같은 mapped netlist와 library를 유지. 이상적인 same-edge clock, uncertainty=0, 단일 사이클 경로에서 주기만 변경.
- 같은 setup 경로의 required/slack은 5ns 감소. arrival은 동일. critical path가 달라졌으면 두 경로 이름을 기록하고 동일 경로인지 먼저 검토.
- 같은 에지의 hold는 주기 변경만으로 개선되지 않음. hold 위반을 clock을 늦추는 것으로 고쳤다고 쓰지 않음.
- DC의 합성 단계 추정값이며 배치배선 후 signoff가 아님. 기능 시뮬레이션 PASS와 timing MET는 다른 검사.
- 실제 예제는 짧은 decode 경로여서 10ns와 5ns 모두 MET일 수 있음. 일부러 5ns VIOLATED를 만들거나 수치를 조작하지 말 것.

학생 기록지:

|항목|10ns setup|5ns setup|10ns hold|5ns hold|
|---|---|---|---|---|
|Startpoint|____|____|____|____|
|Endpoint|____|____|____|____|
|Arrival [단위: ___]|____|____|____|____|
|Required [단위: ___]|____|____|____|____|
|Slack|____|____|____|____|
|MET / VIOLATED|____|____|____|____|

설명 빈칸:

1. SW의 REGWRITE=___, MEMWRITE=___.
2. BEQ의 ZERO=0이면 PCSRC=___, ZERO=1이면 ___.
3. JAL의 목적지 주소는 ___이며 레지스터 저장값은 ___.
4. setup slack의 계산 방향은 ___. hold slack은 ___.
5. 비교 중 compile을 다시 하지 않는 이유는 ___.


## 경로 선택 명령

현재 서버 DC에서는 register cell 컬렉션 대신 핀을 지정합니다. `all_registers -output_pins`는 출발 register의 출력 핀, `all_registers -data_pins`는 도착 register의 데이터 입력 핀입니다. 네 report_timing 줄은 이 핀 사이의 경로만 보고합니다. 옵션 없는 `all_registers`를 넣으면 UID-119/CMD-036 오류로 보고서에 경로가 나오지 않습니다.

## 출력 확인 기준

- `link`, `check_design`: 성공 반환값 `1`, Error 없음.
- `report_units`: Time_unit=1e-09 s (ns), Capacitive_load_unit=1e-15 F (fF).
- `report_clock`: 처음 CLK 하나에 10, 변경 후 CLK 하나에 5. 두 clock을 겹치지 않습니다.
- 합성 뒤 `get_attribute [current_design] is_mapped`: `true`.
- 보고서: Startpoint/Endpoint가 register, Path Group=CLK, max/min, arrival/required/slack 존재.
- `No paths`는 성공이 아닙니다. 경로가 없거나 단위가 다르면 조교에게 보여 주세요.

CTRL_Q는 현재 INSTR를 즉시 저장하지 않습니다. 첫 rising edge에서 instr_q/zero_q에 저장하고, 다음 rising edge에서 제어 결과를 CTRL_Q에 저장합니다. reset이 없어 초기 X는 정상입니다. 이 앞뒤 레지스터는 타이밍 관찰용입니다.

TODO 완성 후에는 Linux에서 `cd ~/DICE/W07/todo/synth`로 이동하고 `dc_shell_queue`부터 같은 순서를 반복합니다. 자기 버전의 `../rtl/CONTROLLER.v`를 읽습니다.

[처음으로](README_KO.md) · [체크포인트](CHECKPOINT_KO.md)
