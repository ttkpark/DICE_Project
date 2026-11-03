# W07 — 제어기 실행과 타이밍 관찰

명령어에 맞는 제어신호를 만들고, 별도로 setup/hold 시간 조건을 확인합니다. **정답 시뮬레이션 → 파형 → DC 한 줄 실행 → TODO T0–T9 전체 제어값 완성** 순서로 진행합니다.

각 명령을 한 줄씩 입력하고 Enter를 누르세요. 실행이 끝난 뒤 출력을 보고 다음 줄로 갑니다. 정답 예제에 Error/Fatal/FAIL이 나오면 조교에게 보여 주세요. TODO/blank의 미완성 상태에서 기능 FAIL은 예상 결과입니다.

## 1. 첫 설치 — Linux 터미널

조교가 `~/DICE/W07`을 설치했으면 2번으로 갑니다. 아래는 홈에 `W07.tar.gz`가 있고 W07을 처음 설치할 때만 사용합니다.

```bash
mkdir -p ~/DICE
ls -ld ~/DICE/W07
```

`No such file or directory`로 W07이 없는 것을 확인한 경우에만 다음으로 갑니다. 이미 있으면 조교와 기존 작업을 백업한 뒤 진행합니다.

```bash
tar -tzf ~/W07.tar.gz
tar -xzf ~/W07.tar.gz -C ~/DICE
```

목록의 모든 파일이 `W07/`로 시작하는지 확인한 뒤 압축을 풉니다.

## 2. 정답 실행 — Linux 터미널

```bash
cd ~/DICE/W07/answer
mkdir -p build
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f filelist.f -top tb_controller -Mdir=build/csrc -o build/simv -l logs/sim.log -R
cat logs/sim.log
```

C01–C16과 마지막 **`CONTROL PASS (16/16)`**를 확인합니다. `run.sh`에도 위 mkdir/VCS 명령이 그대로 있습니다. 로그의 이번 실행 결과를 읽으세요.

## 3. 파형과 RTL 비교 — Linux 터미널

```bash
ls -l build/controller.fsdb
verdi_sub --fsdb build/controller.fsdb --filelist filelist.f --top tb_controller
```

FSDB 수정 시각이 방금 실행한 시각인지 확인합니다. `view.sh`에도 같은 Verdi 명령이 있습니다. GUI는 서버 데스크톱/VNC 또는 X11 화면 연결이 필요합니다.

`tb_controller`의 `INSTR ZERO REGWRITE MEMWRITE ALUSRC RESULTSRC IMMSRC ALUCTRL PCSRC ILLEGAL`을 파형에 추가합니다. 각 C번호는 1ns 구간에 해당하며 C01=0–1ns, C16=15–16ns입니다. 끝 경계에서 다음 입력으로 바뀌므로 구간 중간 값을 봅니다. TB의 `#1`은 검사 대기이며 실제 회로 지연이 아닙니다.

- C05 LW: REGWRITE=1, MEMWRITE=0, RESULTSRC=01.
- C06 SW: REGWRITE=0, MEMWRITE=1, IMMSRC=01.
- C07/C08 BEQ: ZERO=1/0에 따라 PCSRC=1/0.
- C09/C10 JAL: ZERO와 무관하게 PCSRC=1, RESULTSRC=10, IMMSRC=11.
- C11/C15 invalid: 이전 JAL/SW의 쓰기·분기 값이 남지 않고 ILLEGAL=1.

```bash
emacs rtl/CONTROLLER.v
```

opcode/funct3/funct7, 기본값, 각 명령 case, 마지막 PCSRC 식을 찾아봅니다. 포트 연결은 한 핀 한 줄로 명시되어 있습니다. Emacs `M-x verilog-auto` 또는 `C-c C-a`로 AUTOINST 갱신 후 이름을 확인할 수 있습니다.

## 4. DC에서 한 줄씩 합성·타이밍 비교

[DC_STEP_BY_STEP_KO.md](DC_STEP_BY_STEP_KO.md)를 열고 30개 명령을 위에서부터 실행합니다. `source setup.tcl`은 환경만 준비합니다. 10ns에서 한 번 compile하고, 같은 회로의 클럭 주기만 5ns로 바꾸어 네 보고서를 비교합니다. 두 주기 사이에 compile을 다시 실행하지 않습니다.

기능 PASS와 타이밍 MET은 다른 검사입니다. 둘 다 MET이어도 정상이며 실제 slack을 기록합니다.

## 5. TODO 전체 제어값 완성

[CHECKPOINT_KO.md](CHECKPOINT_KO.md)의 순서로 `todo/rtl/CONTROLLER.v`의 제어값 대입 38곳을 모두 확인하고 완성합니다. 기본값·명령별 제어값·PCSRC를 모두 0으로 제공하므로, 정답이 0인 항목은 유지하고 필요한 값과 식을 직접 작성합니다. answer는 공개 정답, todo는 기본 실습, blank는 선택 도전입니다. 세 버전의 TB·wrapper·실행 파일은 같습니다.

## 신호 계약


|출력|폭|의미|
|---|---:|---|
|REGWRITE|1|레지스터 파일 쓰기 허용|
|MEMWRITE|1|데이터 메모리 쓰기 허용|
|ALUSRC|1|0=rs2, 1=immediate|
|RESULTSRC|2|00=ALU, 01=memory, 10=PC+4|
|IMMSRC|2|00=I, 01=S, 10=B, 11=J|
|ALUCTRL|3|000=ADD, 001=SUB, 010=AND|
|PCSRC|1|0=PC+4, 1=PC+immediate|
|ILLEGAL|1|이번 예제에서 미지원=1|

이 선택 코드는 ISA가 강제하는 값이 아니라 **수업의 회로 인터페이스 계약**. 사용하지 않는 선택 출력도 결정된 기본값 0으로 유지. X를 don’t-care처럼 출력하지 않음. JAL에서는 RESULTSRC=10, IMMSRC=11, PCSRC=1. JAL의 [14:12]는 funct3가 아니라 immediate의 일부이므로 funct3 조건을 적용하지 않음.


전체 CPU가 아닌 ADD/SUB/AND/ADDI/LW/SW/BEQ/JAL 부분집합입니다. ZERO는 TB에서 주는 ALU 비교 결과입니다. ILLEGAL은 학습용 표시이며 실제 예외 처리는 구현하지 않습니다. W05 PC와 W06 REGFILE은 다시 만들지 않습니다.

## 예비보고서 — A4 1쪽

opcode·funct3·funct7과 ADD/SUB 구분, LW/SW의 쓰기 제어 차이, 기본값 누락과 latch 및 setup/hold/slack의 의미를 짧게 정리하고 참고자료 출처를 적습니다. 실습 결과나 FPGA 실행은 요구하지 않습니다.

[조교 체크리스트](TA_CHECKLIST_KO.md) · [교수자 해설](instructor/ANSWER_KO.md) · [실제 검증 기록](instructor/VALIDATION.md)
