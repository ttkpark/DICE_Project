# Project 1 INT8 선형계층 - R1.4 기본 배포본과 R1.7 업데이트

## 먼저 할 일

1. `RELEASE_NOTES_KO.md`에서 R1.7 서버 실행 방법, 전체 계층 DDC 제출, CPU 인터페이스 확인.
2. 기존 CPU를 가져오되 TOP은 새 포트 계약 적용. `INSTR`는 입력이며 `READDATA` 입력이 추가됨.
3. TOP의 T1/T2와 CONTROLLER 구현. 미완성 starter가 PASS하는 배포본이 아님.
4. 메모리는 수정하지 않음. `sim/TB_TOP.v`가 `sim/mem/IMEM.v`, `DMEM.v`를 연결함.

## 서버에서 순서대로 실행

```bash
# 새 폴더에서 ZIP 해제
unzip Project1_INT8_Release1p4_20261103.zip
# 패키지로 이동
cd Project1_INT8_R1p4_20261103
# 상위 폴더에 내려받은 R1.7 누적 업데이트 적용
unzip -o ../Project1_R1p7_Update_20261112.zip
# 기준 프로그램 공개 16개 기능 모델 확인 (CPU 기능 PASS와 구분)
python3.12 verify_all.py
# 합성 대상·포트·주기 계약 확인
python3.12 tools/check_release.py
# TOP/CONTROLLER 구현 후 VCS로 공개 16개 CPU 실행
bash run_sim.sh
# 같은 activity·RTL로 DC 합성, STA, CPU power와 SRAM 비용 계산
bash run_ppa.sh
# 제출할 DDC와 합성 계층 확인
ls -lh results/TOP_mapped.ddc
cat reports/cpu_hierarchy.rpt
```

두 실행 스크립트가 DICE의 Python 3.12를 사용하며, `run_ppa.sh`가 `vcd2saif` 경로를 설정합니다. 최종 프로그램을 지정하려면 `bash run_sim.sh --program optimized.hex`처럼 실제 파일명을 사용합니다. 각 명령이 완료된 뒤 다음 줄을 실행합니다. 자세한 단계는 `docs/COMMON_FLOW_KO.md`에 있습니다.

## clock period 하나만 변경

`synth/common.sdc`의 `-period 4.00` 숫자만 팀 목표 주기로 변경. 나머지 SDC 값은 고정. 실행 도구가 이 숫자를 읽어 VCS의 주파수와 power 주파수를 맞춤. RESET은 동기 active-high. `set_case_analysis 0`은 compile 후에만 적용.

## 파일 구분

- `rtl/`: 합성 CPU. `synth/rtl.f`에 CPU 내부 파일만 열거. 추가 모듈은 이 목록에도 추가.
- `sim/TB_TOP.v`, `sim/mem/`, `sim/MEMORY_POWER.v`: 기능·activity 측정 전용. 합성 목록에 넣지 않음.
- `build/`: case별 원본 VCD, 실행 구간 VCD, SAIF. `logs/`: 실행 로그.
- `reports/`: CPU area, setup/hold, case별 power·annotation. `results/ppa_summary.json`: 공개 case 결과 요약.
- `results/TOP_mapped.ddc`: 최종 PPA와 같은 실행에서 생성한 TOP 및 CPU 하위 계층의 DDC. 팀 제출 ZIP에 포함.
- `FUNCTIONAL_VALIDATION.json`: 기준 assembly의 Python 회귀. 학생 CPU나 물리 PPA 통과 증거가 아님.
- `docs/`: R1.4 설명 PDF와 명령 순서. 포트·PPA 전체 계약은 `PROJECT_CONTRACT_KO.md`.

모든 예약 입력 20개는 TB에서 0, 예약 출력 20개는 미연결. 학생의 TB 변경은 공식 채점에 반영되지 않음. 공개 16개 연습과 공식 공개·숨김 24개 평가는 구분.
