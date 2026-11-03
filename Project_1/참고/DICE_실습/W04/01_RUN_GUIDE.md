# 한 줄씩 실행하기

자신의 계정으로 로그인하고 Bash 터미널에서 한 줄씩 실행하세요.
명령 뒤 `#`부터는 설명입니다. 오류가 나면 다음 명령으로 넘어가지 말고 먼저 해결하세요.
학생 파일은 `~/DICE/W04`에 있습니다. 기본 경로는 `todo/lesson`입니다.

## 1. 완성 예제: 더하기·빼기

```bash
cd ~/DICE/W04/todo/lesson # 완성 예제 폴더로 이동
pwd # 현재 계정의 lesson 폴더인지 확인
ls rtl # ALU 회로 파일 확인
ls tb # 제공된 검사 파일 확인
command -v vcs_queue # 서버 VCS 큐 명령 확인
command -v verdi_sub # 서버에서 확인된 Verdi 실행 명령 확인
cat rtl/alu.v # 완성 ALU 코드 읽기
cat 01_addsub.f # ALU와 TB 두 파일만 컴파일하는지 확인
bash 01_run_addsub.sh # 3+5와 8-3과 5-5 및 overflow 경계값 검사
echo $? # 종료 상태 확인, 0만으로 합격 판정하지 않음
cat logs/01_addsub.log # PASS: W04_DEMO01 (4/4)와 FAIL 부재 확인
ls -l build/01_addsub.fsdb # 이번 실행의 FSDB 파형 파일 확인
bash 01_view_addsub.sh # 소스와 파형을 Verdi에서 함께 보기
```

Verdi에서 `tb_01_addsub`의 `a`, `b`, `alucontrol`, `result`, `zero`를 파형 창으로 옮겨 보세요.
`dut` 아래 `sub`, `b_mod`, `sum_ext`, `sum32`, `c`, `v`도 관찰합니다.
`7FFFFFFF + 1`에서는 결과가 `80000000`, carry `c=0`, signed overflow `v=1`입니다.
Verdi 창을 닫은 뒤 다음 단계로 갑니다.

### 스크립트 안의 실제 명령

위 run/view와 같은 동작입니다. 이미 실행했다면 다시 입력할 필요는 없습니다.
`-R`이 컴파일 후 실행까지 하므로 `./build/.../simv`를 따로 실행하지 마세요.

```bash
mkdir -p build/01_addsub # 실행 파일과 컴파일 중간 파일의 폴더 준비
mkdir -p logs # 실행 로그 폴더 준비
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 01_addsub.f -top tb_01_addsub -Mdir=build/01_addsub/csrc -o build/01_addsub/simv -l logs/01_addsub.log -R # VCS 큐에서 컴파일과 검사 실행
verdi_sub --fsdb build/01_addsub.fsdb --filelist 01_addsub.f --top tb_01_addsub # 같은 소스와 파형 열기
```

| 옵션 | 뜻 |
|---|---|
| VCS `--fsdb` | FSDB 기록 코드도 켜고 파형을 저장할 수 있게 컴파일 |
| `-full64` | 서버의 64비트 실행 |
| `-timescale=1ns/1ps` | 시간 단위 없는 모듈의 기본 단위 |
| `-f` | 선택한 RTL 하나와 TB 하나의 목록 |
| `-top` | 실행할 TB 모듈 이름 |
| `-Mdir` | 각 예제의 컴파일 중간 파일 폴더 |
| `-o` | 실행 파일 위치 |
| `-l` | 검사 로그 위치 |
| `-R` | 컴파일 후 즉시 시뮬레이션 |
| Verdi `--fsdb` | 이미 만든 FSDB 파형의 파일 이름 |
| Verdi `--filelist` / `--top` | 파형에 대응하는 소스 목록과 TB 이름 |

## 2. 입력을 바꿔 다시 실행

### 예제 01: A만 바꾸기

첫 `T02` 블록의 `a = 32'h00000003`을 `32'h00000004`로 바꾸세요.
같은 블록의 `expected_result`도 `32'h00000008`에서 `32'h00000009`로 바꿉니다.
B는 5, 제어값은 ADD 그대로입니다. 다른 사례의 상수는 그대로 둡니다.

```bash
emacs -nw tb/tb_01_addsub.v # 첫 사례 A를 4로, 예상 결과를 9로 수정하고 저장·종료
bash 01_run_addsub.sh # 수정한 TB로 새로 컴파일하고 실행
cat logs/01_addsub.log # 4+5=9와 마지막 PASS 및 FAIL 부재 확인
```

입력만 바꾸고 예상값을 바꾸지 않으면 첫 사례 FAIL 후 종료됩니다.
먼저 계산한 예상값과 비교하세요. 출력에 맞춰 임의의 값을 쓰거나 검사문을 지우지 마세요.

### 예제 02: AND·OR·XOR

```bash
bash 02_run_logic.sh # A=0A와 B=0C의 비트 연산 검사
cat logs/02_logic.log # AND=08과 OR=0E와 XOR=06 및 PASS: W04_DEMO02 (3/3) 확인
bash 02_view_logic.sh # 연산 번호에 따라 선택되는 결과 보기
emacs -nw tb/tb_02_logic.v # 세 사례의 A=03과 B=05 및 예상값 01·07·06으로 수정
bash 02_run_logic.sh # 수정한 세 사례를 다시 검사
cat logs/02_logic.log # 세 OK와 마지막 PASS 및 FAIL 부재 확인
```

ALU RTL은 바꾸지 않습니다. `&`와 `|`는 비트별 연산이고 `&&`와 `||`는 참/거짓 연산입니다.

### 예제 03: signed 비교와 시프트

```bash
bash 03_run_compare_shift.sh # 음수 비교와 거리 1·31·4의 시프트 검사
cat logs/03_compare_shift.log # PASS: W04_DEMO03 (10/10)와 FAIL 부재 확인
bash 03_view_compare_shift.sh # SLT의 sub·sum32·v_raw·slt_bit 및 시프트 결과 관찰
emacs -nw tb/tb_03_compare_shift.v # SLL의 T27만 B=00000020과 예상 결과=00000001로 수정
bash 03_run_compare_shift.sh # B=32의 하위 5비트가 0이어서 이동하지 않는지 검사
cat logs/03_compare_shift.log # 변경 후에도 10개 사례와 최종 PASS 확인
```

예제 03의 T21은 **20~30 ns**, T27은 **60~70 ns**입니다.
전체 checkpoint에서는 사례 순서가 달라 T21은 **200~210 ns**, T27은 **260~270 ns**입니다.
SLT의 부호 보정은 `v_raw`를 보세요. 최종 관측 신호 `v`는 SLT에서 0으로 표시됩니다.
`B=00000024`는 36이지만 `b[4:0]`는 4입니다. SRL은 빈자리를 0으로 채웁니다.

## 3. TODO 12곳 작성과 전체 검사

checkpoint TB는 고정 검사이므로 입력·기대값·비교문을 수정하지 않습니다.
lesson의 완성 예제를 참고하여 TODO를 작성하세요.

```bash
cd ~/DICE/W04/todo/checkpoint # 학생이 ALU를 작성할 폴더로 이동
pwd # lesson이 아닌 checkpoint인지 확인
cat TODO_GUIDE.md # TODO 작성 순서와 통과 기준 읽기
emacs -nw rtl/alu.v # CP01~CP12 작성 후 TODO를 DONE으로 바꾸고 AUTO·저장·종료
bash 01_run_alu_check.sh # 본인 ALU의 고정 34개 사례를 새로 검사
echo $? # 종료 상태 확인, 0만으로 통과 판정하지 않음
cat logs/alu_check.log # T01~T34 OK와 PASS: W04_CHECKPOINT (34/34) 및 FAIL 부재 확인
ls -l build/alu_check.fsdb # 이번 실행의 FSDB 확인
ls -l build/alu_check.vcd # 함께 저장된 VCD 확인
bash 01_view_alu_check.sh # T21과 T27 또는 T32를 조교에게 설명
```

수정 전 TODO는 컴파일 성공 후 T01에서 FAIL하는 것이 정상입니다.
`blank/checkpoint/rtl/alu.v`는 빈 파일이므로 작성 전 컴파일 실패합니다.

직접 명령을 입력하려면 다음과 같습니다.

```bash
mkdir -p build/alu_check # 실행 파일과 중간 파일 폴더 준비
mkdir -p logs # 검사 로그 폴더 준비
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f alu_check.f -top tb_alu_check -Mdir=build/alu_check/csrc -o build/alu_check/simv -l logs/alu_check.log -R # 본인의 ALU를 컴파일하여 34개 사례 검사
verdi_sub --fsdb build/alu_check.fsdb --filelist alu_check.f --top tb_alu_check # 검사에 사용한 소스와 파형 보기
```

## 4. Emacs 저장과 AUTO

1. `Alt+x` → `verilog-mode` → Enter.
2. 지정된 입력 또는 TODO 식을 수정합니다.
3. `Alt+x` → `verilog-auto` → Enter. 포트 목록·인스턴스 연결을 정리합니다.
4. `Ctrl+x` 다음 `Ctrl+s`로 저장합니다.
5. `Ctrl+x` 다음 `Ctrl+c`로 종료하고 다음 터미널 명령을 실행합니다.

AUTO는 회로 동작을 만들어 주지 않습니다. 한 줄에 한 포트·명시적 이름 연결을 유지하세요.
처음 배포한 코드에도 실제 포트와 연결을 모두 넣어 AUTO를 실행하지 않아도 동작합니다.
vim을 쓰려면 `i`로 편집하고 Esc → `:wq` → Enter로 저장·종료하세요.
vim에서는 이미 제공된 포트 목록과 연결을 유지합니다.

```bash
vim rtl/alu.v # Emacs 대신 선택하는 편집 방법, 저장 후 원래 실행 순서로 복귀
```

## 5. 파형과 오류 확인

- VCS 실행은 VCD와 FSDB를 함께 만듭니다. Verdi는 3주차처럼 FSDB를 엽니다.
- GUI 연결이 없으면 VCS 검사부터 실행하고, 파형은 수업의 X11/VNC 접속 후 확인하세요.
- DISPLAY를 임의로 설정하지 마세요. 창이 안 뜨면 접속 방법부터 확인하세요.
- 큐 대기 중 같은 명령을 반복 제출하지 마세요.
- 컴파일 실패 뒤에는 이전 로그·파형이 남아 있을 수 있습니다. 이번 컴파일 성공과 기록 시각을 확인하세요.
- 파형을 다시 열기 전에 바뀐 소스의 run을 재실행하세요.
- 로그의 개별 `OK:`와 마지막 `PASS:`를 구분하세요. 하나라도 FAIL이면 수정 후 재실행합니다.

```bash
synopsys_queue_status # 다른 터미널에서 큐 대기 상태 확인
vcs_queue --help # VCS 실행 도구의 한글 도움말 확인
verdi_sub --help # 파형 보기 도구의 한글 도움말 확인
```
