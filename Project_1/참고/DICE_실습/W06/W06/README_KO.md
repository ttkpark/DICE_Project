# W06 — 이 순서대로 따라 하세요

**레슨 1·2는 시뮬레이션**, **레슨 3은 합성**입니다. 레슨 1 → 레슨 2 → 체크포인트 → 레슨 3 순서로 진행합니다.

명령은 한 줄씩 입력하고 Enter를 누릅니다. **Error / Fatal / FAIL이 나오면 멈추고 조교에게 보여 주세요.**

## 1. 레슨 1 — 두 레지스터 읽기

[예제 1 명령어 열기](todo/lesson/01_ports/README_KO.md)

완성된 RTL을 실행해서 x1=10, x2=20을 확인합니다.

## 2. 레슨 2 — 쓰기 타이밍과 x0

[예제 2 명령어 열기](todo/lesson/02_timing_x0/README_KO.md)

쓰기 에지 전후 값과 x0=0을 확인합니다.

## 3. 체크포인트 — 빈칸 6개 완성

Linux 터미널에서 입력합니다. 편집기에서 `TODO T1`~`T6`을 완성하고 저장한 뒤 나옵니다. TB는 수정하지 않습니다.

```bash
cd ~/DICE/W06/todo/checkpoint
emacs rtl/REGFILE.v
mkdir -p build
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f checkpoint.f -top tb_checkpoint -Mdir=build/csrc -o build/simv -l build/run.log -R
```

방금 실행에서 **`W06 CHECKPOINT PASS (14/14)`**가 나오면 파형을 엽니다.

```bash
verdi_sub --fsdb build/checkpoint.fsdb --filelist checkpoint.f --top tb_checkpoint
```

`clk reset we3 a1 a2 a3 wd3 rd1 rd2`를 파형에 추가하세요. **쓰기 금지일 때 유지, 상승 에지에서 변경, x0=0**을 조교에게 설명하면 됩니다. 정답 참고는 허용합니다: [정답과 해설](instructor/ANSWER_KO.md).

## 4. 레슨 3 — 합성

[레슨 3 합성 명령어 열기](todo/lesson/03_synthesis/README_KO.md)

환경 설정만 `source setup.tcl`로 읽습니다. 나머지는 위에서부터 한 줄씩 입력합니다. 합성은 별도 채점이나 제출이 없습니다.

완성한 내 체크포인트를 합성할 때는 [체크포인트용 명령어](DC_STEP_BY_STEP_KO.md)를 사용합니다.

## 기억할 것

레지스터 파일은 **번호로 고른 두 값을 바로 읽고, 한 값을 클럭 상승 에지에서 저장**합니다. A1/A2는 읽을 번호, A3는 쓸 번호, WD3는 쓸 값입니다. WE3=0이면 유지하고, x0는 항상 0입니다.

Emacs 대신 `vim rtl/REGFILE.v`를 써도 됩니다. Emacs AUTO는 `C-c C-a`이며 배포 코드에는 이미 전개되어 있습니다. `blank`는 선택 심화용, `answer`는 정답이며 기본 실습은 `todo`입니다.

## 예비보고서 — A4 1쪽

레지스터 파일의 역할과 2읽기·1쓰기, 5비트 번호의 이유, 조합 읽기와 순차 쓰기, WE3=0과 x0, 시뮬레이션과 합성의 차이를 조사합니다. 그림이나 짧은 예시와 출처를 넣으세요.
