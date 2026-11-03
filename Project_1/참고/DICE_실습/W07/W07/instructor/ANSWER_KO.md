# W07 교수자 해설

## T0–T9: 모든 제어값

TODO는 기본값·명령별 제어값·PCSRC의 대입 38곳을 모두 0으로 제공합니다. 모든 항목을 확인하되 정답이 0인 16곳은 유지하고, 나머지 22곳의 값·식을 수정합니다. 명령 블록에서 대입하지 않는 신호는 T0 기본값을 사용합니다.

|번호|정답 대입값|설명|
|---|---|---|
|T0|REGWRITE=0, MEMWRITE=0, ALUSRC=0, RESULTSRC=00, IMMSRC=00, ALUCTRL=000, branch=0, jump=0, ILLEGAL=1|미지원 명령의 안전 기본값|
|T1 ADD|REGWRITE=1, ILLEGAL=0|ADD 연산·선택값은 기본값 사용|
|T2 SUB|REGWRITE=1, ALUCTRL=001, ILLEGAL=0|SUB 제어 코드|
|T3 AND|REGWRITE=1, ALUCTRL=010, ILLEGAL=0|AND 제어 코드|
|T4 ADDI|REGWRITE=1, ALUSRC=1, ILLEGAL=0|즉시값 덧셈|
|T5 LW|REGWRITE=1, ALUSRC=1, RESULTSRC=01, ILLEGAL=0|주소 계산 후 메모리 읽기 결과 저장|
|T6 SW|MEMWRITE=1, ALUSRC=1, IMMSRC=01, ILLEGAL=0|S 즉시값으로 주소 계산, 메모리 쓰기|
|T7 BEQ|branch=1, IMMSRC=10, ALUCTRL=001, ILLEGAL=0|B 즉시값과 SUB 비교|
|T8 JAL|REGWRITE=1, RESULTSRC=10, IMMSRC=11, jump=1, ILLEGAL=0|PC+4 저장, J 즉시값과 무조건 점프|
|T9 PCSRC|`jump \| (branch & ZERO)`|JAL 무조건 이동, BEQ는 ZERO일 때 이동|

표의 숫자는 2진수이며 실제 대입은 신호 폭에 맞는 Verilog 리터럴을 사용합니다. T9 전체 행:

```verilog
assign PCSRC = jump | (branch & ZERO);
```

표에서 `|`는 OR입니다. SW는 REGWRITE=0/MEMWRITE=1. BEQ의 PCSRC는 ZERO=0/1에 따라 0/1. JAL의 목적지는 PC+imm, 레지스터 저장값은 PC+4입니다. 이 제어기 안에는 주소 계산기/PC/메모리가 없습니다.

## 고정 TB의 16개 검사

|검사|명령/목적|INSTR|ZERO|expected 12비트|
|---|---|---|---:|---|
|C01|ADD|003100b3|0|100_00_00_000_0_0|
|C02|SUB|403100b3|0|100_00_00_001_0_0|
|C03|AND|003170b3|0|100_00_00_010_0_0|
|C04|ADDI|00510093|0|101_00_00_000_0_0|
|C05|LW|00412083|0|101_01_00_000_0_0|
|C06|SW|00312223|0|011_00_01_000_0_0|
|C07|BEQ taken|00208463|1|000_00_10_001_1_0|
|C08|BEQ not taken|00208463|0|000_00_10_001_0_0|
|C09|JAL ZERO=0|008000ef|0|100_10_11_000_1_0|
|C10|JAL ZERO=1|008000ef|1|100_10_11_000_1_0|
|C11|unsupported opcode after JAL|ffffffff|1|000_00_00_000_0_1|
|C12|unsupported R funct7|023100b3|0|000_00_00_000_0_1|
|C13|unsupported load funct3|00410083|0|000_00_00_000_0_1|
|C14|SW before invalid|00312223|0|011_00_01_000_0_0|
|C15|invalid after SW|ffffffff|0|000_00_00_000_0_1|
|C16|unsupported branch|00209463|1|000_00_00_000_0_1|


TODO 제공 상태는 모든 출력이 0이므로 C01–C16 모두 실패합니다(0/16 PASS). 기본값의 ILLEGAL도 0이므로 invalid 검사 역시 실패합니다. blank는 지원 명령 11개에서 실패하고 invalid 5개는 안전 기본값으로 통과합니다. 실패 후에도 16개를 모두 검사하고 마지막 $fatal로 종료합니다.

## 조합논리와 타이밍

REGWRITE/MEMWRITE/branch/jump 기본값은 0, ILLEGAL 기본값은 1입니다. 지원 명령에서만 필요한 신호를 켜므로 invalid로 바뀌어도 이전 값이 남지 않습니다. JAL [14:12]는 immediate 일부로 funct3 검사를 적용하지 않습니다.

관찰 wrapper의 instr_q/zero_q → CONTROLLER → CTRL_Q가 register 경로입니다. nonblocking 대입으로 현재 에지의 CTRL_Q는 이전 instr_q를 해석한 결과를 저장합니다. reset 없는 초기 X를 기능 오류로 판정하지 않습니다.

Setup slack = required − arrival, hold slack = arrival − required. 같은 mapped netlist에서 CLK만 10ns→5ns로 바꾸면 같은 setup 경로의 required/slack은 5ns 줄고 arrival은 같습니다. same-edge hold는 주기 변경만으로 개선되지 않습니다. 재합성하면 셀 선택/논리 최적화가 달라질 수 있어 비교 중 compile하지 않습니다. DC 추정값은 배치배선 이후 signoff가 아닙니다.

## 오류 해결

- `command not found`: W06와 같은 EDA 환경/큐 wrapper가 설정된 터미널인지 확인.
- filelist/RTL을 못 찾음: answer/todo/blank 또는 해당 synth 디렉터리에 있는지 `pwd`로 확인.
- 로그 FAIL인데 shell 종료 상태 0: 이 서버 VCS -R wrapper의 동작. 실제 로그의 PASS/FAIL을 판정.
- FSDB 없음: VCS 명령의 --fsdb와 TB DUMP_FSDB 블록 확인. 생성 시각 확인 후 Verdi 실행.
- Verdi DISPLAY 없음: 서버 데스크톱/VNC 또는 X11 화면 연결 확인.
- library/link 오류: library_setup.tcl의 경로·읽기 권한 확인. DB는 배포 압축에 넣지 않음.
- check_timing 경고 또는 경로 없음: CLK/입출력 제약, top CONTROL_TIMING, 완성 RTL 여부를 확인. 원인 해결 후 진행.
- 5ns에서도 MET: 정상 가능. 숫자를 바꾸거나 일부러 위반을 만들지 않음.

[학생 안내](../README_KO.md) · [검증 기록](VALIDATION.md)
