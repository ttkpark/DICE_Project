# W07 체크포인트 — 모든 제어값 완성 (T0–T9)

정답의 16/16 PASS와 파형을 먼저 확인합니다. `todo/rtl/CONTROLLER.v`의 제어값 대입 38곳을 모두 확인하고 완성합니다. 모든 TODO 우변은 비트 폭에 맞춘 0(`1'b0`, `2'b00`, `3'b000`)으로 통일되어 있으며, 기본값의 ILLEGAL과 마지막 PCSRC도 포함합니다. 정답이 0인 항목은 의미를 확인한 뒤 유지합니다. 제공 TB는 수정하지 않습니다. answer 참고는 허용하며 각 신호의 의미를 설명합니다.

|번호|고칠 위치|생각할 내용|
|---|---|---|
|T0|기본값 9곳|미지원 명령의 쓰기·분기 금지와 ILLEGAL 표시|
|T1|ADD의 REGWRITE, ILLEGAL|레지스터 쓰기와 지원 여부|
|T2|SUB의 REGWRITE, ALUCTRL, ILLEGAL|레지스터 쓰기와 W04 SUB 코드|
|T3|AND의 REGWRITE, ALUCTRL, ILLEGAL|레지스터 쓰기와 W04 AND 코드|
|T4|ADDI의 REGWRITE, ALUSRC, ILLEGAL|즉시값을 ALU에 전달|
|T5|LW의 REGWRITE, ALUSRC, RESULTSRC, ILLEGAL|주소 계산과 메모리 읽기 결과 저장|
|T6|SW의 MEMWRITE, ALUSRC, IMMSRC, ILLEGAL|주소 계산, 저장 즉시값과 메모리 쓰기|
|T7|BEQ의 branch, IMMSRC, ALUCTRL, ILLEGAL|비교 연산과 분기 즉시값|
|T8|JAL의 REGWRITE, RESULTSRC, IMMSRC, jump, ILLEGAL|복귀 주소 저장과 무조건 점프|
|T9|assign PCSRC|JAL은 항상, BEQ는 ZERO=1일 때 이동|

각 명령 블록에 대입이 없는 신호는 T0의 기본값을 사용합니다. 명령어를 판별하는 opcode/funct3/funct7 조건은 제공된 구조를 사용합니다.

Linux 터미널에서 한 줄씩 입력합니다. Emacs에서 T0–T9의 모든 제어값을 확인·수정하고 저장한 뒤 터미널로 돌아옵니다. Emacs 대신 `vim rtl/CONTROLLER.v`도 가능합니다.

```bash
cd ~/DICE/W07/todo
emacs rtl/CONTROLLER.v
mkdir -p build
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f filelist.f -top tb_controller -Mdir=build/csrc -o build/simv -l logs/sim.log -R
cat logs/sim.log
```

미완성 TODO/blank도 컴파일은 되지만 기능 검사는 FAIL이 나옵니다. TODO 제공 상태는 모든 출력이 0이므로 0/16 PASS이며 C01–C16 모두 실패합니다. 특히 ILLEGAL 기본값도 직접 완성해야 미지원 명령 검사를 통과합니다. 수정 후 방금 실행한 로그에서 **`CONTROL PASS (16/16)`**를 확인합니다. wrapper의 종료 상태 0만으로 통과를 판단하지 않습니다.

```bash
ls -l build/controller.fsdb
verdi_sub --fsdb build/controller.fsdb --filelist filelist.f --top tb_controller
```

조교에게 각 명령의 제어값과 0으로 유지한 이유, BEQ의 ZERO=0/1, JAL, invalid 직후 안전 기본값을 설명하세요. [타이밍 기록지](DC_STEP_BY_STEP_KO.md)의 실제 보고서 4개와 해석도 확인받습니다.

blank는 선택 도전용입니다. 포트와 기본값만 주어지므로 opcode decode와 PCSRC를 직접 완성합니다. 상수 대입만 있는 초기 blank에서는 입력 감도 목록을 명시하여 기본값이 실제로 평가되도록 했습니다. 기능 로직을 완성하면 `always @*`를 사용합니다.

[전체 순서](README_KO.md) · [정답 해설](instructor/ANSWER_KO.md)
