# Project 1 INT8 선형계층 - Release 1.4 (2026-11-03)

## 먼저 할 일

1. `RELEASE_NOTES_KO.md`의 R1.4 변경 사항 확인.
2. 기존 CPU를 가져오되 TOP은 새 포트 계약 적용. `INSTR`는 입력이며 `READDATA` 입력이 추가됨.
3. TOP의 T1/T2와 CONTROLLER 구현. 미완성 starter가 PASS하는 배포본이 아님.
4. 메모리는 수정하지 않음. `sim/TB_TOP.v`가 `sim/mem/IMEM.v`, `DMEM.v`를 연결함.

## 서버에서 순서대로 실행

```bash
# 새 폴더에서 ZIP 해제
unzip Project1_INT8_Release1p4_20261103.zip
# 패키지로 이동
cd Project1_INT8_R1p4_20261103
# 기준 프로그램 공개 16개 기능 모델 확인 (CPU 기능 PASS와 구분)
python3 verify_all.py
# 합성 대상·포트·주기 계약 확인
python3 tools/check_release.py
# TOP/CONTROLLER 구현 후 VCS로 공개 16개 CPU 실행
bash run_sim.sh
# 같은 activity·RTL로 DC 합성, STA, CPU power와 SRAM 비용 계산
bash run_ppa.sh
```

`run_sim.sh`는 서버의 `vcs_queue`, `run_ppa.sh`는 `vcd2saif`와 `dc_shell_queue` 사용. 각 명령이 완료된 다음 줄 실행. 자세한 단계와 DC 내부 명령은 `docs/COMMON_FLOW_KO.md`.

## clock period 하나만 변경

`synth/common.sdc`의 `-period 4.00` 숫자만 팀 목표 주기로 변경. 나머지 SDC 값은 고정. 실행 도구가 이 숫자를 읽어 VCS의 주파수와 power 주파수를 맞춤. RESET은 동기 active-high. `set_case_analysis 0`은 compile 후에만 적용.

## 파일 구분

- `rtl/`: 합성 CPU. `synth/rtl.f`에 CPU 내부 파일만 열거. 추가 모듈은 이 목록에도 추가.
- `sim/TB_TOP.v`, `sim/mem/`, `sim/MEMORY_POWER.v`: 기능·activity 측정 전용. 합성 목록에 넣지 않음.
- `build/`: case별 원본 VCD, 실행 구간 VCD, SAIF. `logs/`: 실행 로그.
- `reports/`: CPU area, setup/hold, case별 power·annotation. `results/ppa_summary.json`: 공개 case 결과 요약.
- `FUNCTIONAL_VALIDATION.json`: 기준 assembly의 Python 회귀. 학생 CPU나 물리 PPA 통과 증거가 아님.
- `docs/`: R1.4 설명 PDF와 명령 순서. 포트·PPA 전체 계약은 `PROJECT_CONTRACT_KO.md`.

모든 예약 입력 20개는 TB에서 0, 예약 출력 20개는 미연결. 학생의 TB 변경은 공식 채점에 반영되지 않음. 공개 16개 연습과 공식 공개·숨김 24개 평가는 구분.
