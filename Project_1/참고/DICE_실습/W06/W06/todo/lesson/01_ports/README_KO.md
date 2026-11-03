# 예제 1 — 두 레지스터 읽기

**시뮬레이션 → 파형 확인** 순서입니다.

한 줄씩 입력하고 Enter를 누르세요. **Error / Fatal / FAIL이 나오면 멈추고 조교에게 보여 주세요.** `--More--`에서는 Space를 누릅니다.

## 1. 시뮬레이션 — Linux 터미널

```bash
cd ~/DICE/W06/todo/lesson/01_ports
mkdir -p build
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f filelist.f -top tb_ports -Mdir=build/csrc -o build/simv -l build/run.log -R
```

방금 실행에서 **`W06 PORTS PASS (6/6)`**가 나오면 다음으로 갑니다.

## 2. 파형 보기 — Linux 터미널

```bash
verdi_sub --fsdb build/ports.fsdb --filelist filelist.f --top tb_ports
```

`clk reset we3 a1 a2 a3 wd3 rd1 rd2`를 파형에 추가합니다. 파형에서 x1=10, x2=20을 확인합니다. Verdi를 닫으면 이 레슨은 끝입니다.


합성은 별도 [레슨 3](../03_synthesis/README_KO.md)에서 합니다. [전체 순서](../../../README_KO.md)
