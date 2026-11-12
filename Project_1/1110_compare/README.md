# 1110 비교 실험 (R1.4)

세 CPU 를 같은 R1.4 공통 flow 로 다시 잰다. 각 폴더는 `Project1_INT8_R1p4_20261103` 패키지 그대로이고 `rtl/CORE.v` 만 다르다
(TOP·CONTROLLER·TB·메모리·SDC·측정 도구·프로그램 HEX 는 세 폴더가 같다).

| 폴더 | CORE | 분기 판정 | 넣은 개선 |
|---|---|---|---|
| `1110_single_cycle` | 배포 기준 단일 사이클 (무수정) | 같은 cycle | 없음 |
| `1110_pipeline_ID` | 5단 파이프라인, ID 분기판 | ID (taken 시 1 cycle 손실) | 포워딩 select 를 ID 에서 미리 계산, 버블 때 제어 비트만 0, result mux 를 MEM 단으로 |
| `1110_pipeline_EX` | 5단 파이프라인, EX 분기판 | EX (taken 시 2 cycle 손실) | 위 세 가지 + ZeroE 를 ALU 와 병렬인 비교기로 |

개선은 모두 포트·ISA(기본 8명령)·동기 RESET 계약을 건드리지 않고, cycle 수도 개선 전과 같다.

## 돌리는 법 (수업 서버)

```bash
cd 1110_compare
bash run_all.sh 2>&1 | tee run_all.log
```

`run_all.sh` 하나가 세 폴더를 차례로 들어가 주기 탐색 → 주기 선택 → 공식 측정(`run_flow.py sim` → `ppa`)을 하고,
끝에 `results/summary.md` 에 비교표를 만든다. 후보 주기와 프로그램 목록은 `run_all.sh` 맨 위 "설정" 에서 고친다.

- 주기는 소수 둘째 자리까지 쓴다 (`1.70`). 이유는 `run_all.sh` 설정 주석 참고.
- 주기 탐색(`tools/sweep_timing.tcl`)은 공식 `synth/run_ppa.tcl` 과 같은 `compile` 을 쓴다. 최종 PASS 판정과 전력은 공식 flow 가 낸다.
- 표의 소수 자리: 주기 2, cycle 4, T 4, slack 4, 면적 2, 전력 4.

## 로컬 기능 확인 (2026-11-10, ModelSim)

세 CORE 모두: 프로그램 4종 × 공개 16 case, 실행 도중 RESET 재인가, 해저드 지향 시험, 무작위 프로그램 150개를
ISA 모델과 store 순서·주소·데이터·최종 DMEM 까지 비교. 서버의 VCS·DC 실행은 아직 하지 않았다.
