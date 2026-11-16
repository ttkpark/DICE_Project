# DICE 서버에서 최종 조합 돌리기 (EX + `int8_horner4`, 1.52 ns)

제출본과 같은 결과를 서버에서 다시 얻는 순서다. 전부 끝나면 `results/ppa_summary.json`이 저장소에 보관한 2026-11-14 측정과 같아야 한다.

| 항목 | 기대값 |
|---|---:|
| 기능 | 공개 16/16 PASS |
| 평균 cycle | 491.25 |
| setup / hold slack | +0.000328541 / +0.102992 ns |
| T | 0.746700 µs |
| A | 100,344.24 µm² |
| P | 16.2857 mW |
| fingerprint | `9497435a…73705` |

기대값의 원본은 [`measurements/R1p7_20261114/int8_horner4/results/ppa_summary.json`](../measurements/R1p7_20261114/int8_horner4/results/ppa_summary.json)이다.

## 1. 폴더 준비

서버에 저장소가 이미 있으면 최신으로 맞춘다. 없으면 새로 받는다.

```bash
# 이미 있을 때
cd <저장소>/Project_1/Project1_R1p7_Update_20261112
git pull

# 처음일 때
git clone https://github.com/ttkpark/DICE_Project.git
cd DICE_Project/Project_1/Project1_R1p7_Update_20261112
```

서버에서 `git`을 쓸 수 없으면 GitHub의 ZIP을 받아 서버에서 `unzip`한다. Windows에서 푼 폴더를 그대로 올리면 줄바꿈이 CRLF로 바뀌어 스크립트가 깨진다.

이전 실행의 결과가 남아 있으면 먼저 옮겨 둔다. `run_sim.sh`와 `run_ppa.sh`는 `results/`, `reports/`, `logs/`를 덮어쓴다.

```bash
B=~/p1_backup_$(date +%m%d_%H%M); [ -d results ] && mkdir -p $B && cp -r results reports logs $B/
```

## 2. 주기를 1.52 ns로 맞춘다

저장소의 기본 `synth/common.sdc`는 1.62 ns다. 1.52 ns 실행에 쓴 SDC를 덮어쓴다. 두 파일은 `-period` 숫자만 다르다.

```bash
cp measurements/R1p7_20261114/int8_horner4/synth/common.sdc synth/common.sdc
grep -n "create_clock" synth/common.sdc      # -period 1.52 가 보여야 한다
```

## 3. 실행

```bash
python3.12 tools/check_release.py
bash run_sim.sh --program programs/int8_horner4.hex
bash run_ppa.sh
```

- `run_sim.sh`는 case마다 `PASS CPU <case> <cycle> cycles`를 찍고 `TOTAL CPU PASS 16/16.`으로 끝난다. `demo`는 485 cycle이다.
- `run_ppa.sh`는 `vcd2saif`와 `dc_shell_queue`를 차례로 부르고, 마지막에 `ppa_summary.json` 내용을 화면에 찍는다. DC 라이선스 대기열에 따라 시간이 걸린다.
- 둘 중 하나가 `FAIL COMMON FLOW: ...`로 끝나면 5절을 본다.

## 4. 결과 확인

보관한 측정과 한 번에 비교한다. 아무것도 출력되지 않고 `SAME`만 나오면 재현된 것이다.

```bash
diff results/ppa_summary.json measurements/R1p7_20261114/int8_horner4/results/ppa_summary.json && echo SAME
```

다르게 나오면 어느 값이 다른지 본다.

```bash
cat results/ppa_status.json                                   # timing_pass 1, slack 두 개
grep -E '"(period_ns|mean_cycles|time_us|total_area_um2|total_power_mw|fingerprint)"' results/ppa_summary.json
grep -c "" reports/cpu_hierarchy.rpt && grep -n -E "TOP|CORE|CONTROLLER" reports/cpu_hierarchy.rpt | head
ls -lh results/TOP_mapped.ddc                                 # 약 416 KB
```

- `fingerprint`만 다르면 소스 파일 내용이 다른 것이다. `git status`로 고친 파일이 있는지, 줄바꿈이 CRLF인지 확인한다.
- `timing_pass`가 0이면 5절의 "타이밍 실패"를 본다.

제출 ZIP을 이 실행으로 다시 만들 때는 `results/`, `reports/`, `logs/` 세 폴더를 함께 가져간다. 세 폴더는 같은 실행의 것이어야 한다.

## 5. 문제가 생기면

| 증상 | 원인과 조치 |
|---|---|
| `$'\r': command not found`, `bad interpreter` | 줄바꿈이 CRLF다. `file run_sim.sh`로 확인하고 `git clone`으로 다시 받는다. 급하면 `sed -i 's/\r$//' run_sim.sh run_ppa.sh tools/*.py synth/*` |
| `Python 3.12 was not found` | DICE 수업 서버가 아닌 곳이다. 스크립트는 `/usr/bin/python3.12`를 쓴다 |
| `vcd2saif was not found` | 위와 같다. `run_ppa.sh`가 `/opt/eda/synopsys/products/syn/V-2023.12-SP5/bin`을 찾는다 |
| `CPU functional check failed: <case>` | `logs/<case>.log`를 본다. `--program` 경로와 `rtl/`이 저장소와 같은지 확인한다 |
| `DC flow incomplete` | `logs/dc_ppa.log`의 끝을 본다. 로그 중간의 `error "P1: ..."` 줄은 Tcl 스크립트 본문이 찍힌 것이라 오류가 아니다. 줄 맨 앞이 `Error:`인 것만 실제 오류다 |
| 타이밍 실패 (`timing_pass` 0) | 1.52 ns의 setup 여유는 0.3 ps뿐이다. 먼저 SDC가 저장소 것과 같은지, RTL을 고치지 않았는지 확인한다. 같은데도 실패하면 결과를 그대로 보관하고 팀에 알린다. 주기를 바꾸면 제출 수치 전체가 바뀐다 |
| `RTL/program/constraints changed: rerun run_sim.sh` | `run_sim.sh` 뒤에 RTL·SDC·프로그램을 고친 것이다. `run_sim.sh`부터 다시 돌린다 |
| `Run a successful run_sim.sh first` | `run_sim.sh`가 16/16으로 끝나지 않았다. 그쪽 오류부터 해결한다 |

## 6. 끝난 뒤

다른 프로그램을 1.62 ns로 다시 재려면 SDC를 되돌린다.

```bash
git checkout synth/common.sdc
```

## 제출 ZIP만으로 처음부터 재현하기

저장소 없이 제출 ZIP과 수업 배포 ZIP 두 개만으로도 돌릴 수 있다. ZIP 안의 `run/reproduce.sh`가 R1.4 패키지를 새로 풀고 R1.7 업데이트를 적용한 뒤, 제출본의 RTL·SDC(1.52 ns)·프로그램·도구를 넣고 3절의 세 명령을 실행한다.

```bash
unzip Project1_TEAM_01.zip
bash TEAM_01/run/reproduce.sh ~/Project1_INT8_Release1p4_20261103.zip ~/Project1_R1p7_Update_20261112.zip ~/p1_repro
R=~/p1_repro/Project1_INT8_R1p4_20261103
diff <(grep -v fingerprint $R/results/ppa_summary.json) <(grep -v fingerprint TEAM_01/results/ppa_summary.json) && echo SAME
grep fingerprint $R/results/ppa_summary.json     # 9b4281ce…d724 이면 정상
```

fingerprint 한 줄은 다르게 나오는 것이 정상이다. 공식 R1.4 ZIP의 `cases/*` 48개는 줄바꿈이 CRLF이고, 저장소 사본(제출본 측정에 씀)은 git을 거쳐 LF다. fingerprint가 `cases/*`까지 해시하므로 공식 ZIP 재현은 `9b4281ce…d724`, 제출본은 `9497435a…73705`가 된다. 2026-11-15 PC에서 두 ZIP으로 같은 폴더를 만들어 확인했다: case의 CR만 지우면 `9497435a…`와 정확히 같고, RTL·SDC·HEX·TB·Tcl·도구 해시는 모두 제출본 기록과 같다. 숫자(cycle·T·A·P·slack)는 같아야 한다.

이 스크립트는 `fastv2` 판에서 쓰던 것을 프로그램 이름과 주기만 바꾼 것이고, `horner4` 판으로는 아직 서버에서 돌려 보지 않았다.
