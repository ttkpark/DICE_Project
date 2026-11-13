# 팀 EX 작업본 · R1.7

이 폴더에는 test 6 `1110_pipeline_EX`의 5단 EX 분기 CPU와 교수님 R1.7 업데이트가 적용되어 있습니다. RTL과 두 `v2` 프로그램의 내용은 GitHub `ffaa3cd`의 서버 측정 사본과 일치합니다.

| 파일 | 용도 |
|---|---|
| `rtl/TOP.v`, `rtl/CORE.v`, `rtl/CONTROLLER.v` | 합성할 CPU 소스 |
| `programs/int8_fastv2.s/.hex/.lst` | 현재 성능 우선 후보. 193 word, IMEM 256 구간 |
| `programs/int8_opt64v2.s/.hex/.lst` | 작은 IMEM을 유지하는 비교 후보. 63 word, IMEM 64 구간 |
| `programs/int8_small`, `int8_opt64`, `int8_fast`의 `.s/.hex/.lst` | 팀원 비교 실험에 쓰인 이전 프로그램 3종 |
| `programs/legacy_single_cycle/` | 초기 단일 사이클용 `small`·`fast`. 종료부에서 DONE 주소와 토큰을 읽는 순서가 다름 |
| `programs/tests/hazard_test.s/.hex/.lst` | 팀원의 해저드 시험 프로그램. 전용 시험의 정답을 사용 |
| `baseline_int8_fc_slow.s/.hex/.lst` | 교수님이 배포한 느린 기준 프로그램. `verify_all.py`의 검사 대상이며 `--program` 생략 시 선택됨 |
| `cases/`, `sim/` | 공개 16개 입력과 공통 테스트벤치·외부 메모리 모델 |
| `synth/common.sdc` | 첫 측정 주기 1.62 ns. 기존 EX 측정에서 통과한 값이며 R1.7에서도 STA 확인 필요 |
| `archive/pipeline_ID/CORE.v` | 팀원의 개선 ID 분기판. 이전 R1.4 측정 주기 2.36 ns |
| `archive/single_cycle/CORE.v` | 팀원이 비교에 사용한 단일 사이클판. 이전 R1.4 측정 주기 3.82 ns |
| `docs/` | 교수님 배포 명세, 평가 계약, 릴리즈 노트와 공통 실행 안내 |
| [발표 PPTX](presentation/project1.pptx) | 팀원이 작성한 18장 발표 초안 |
| [팀 실험 정리 HTML](docs/PRESENTATION_1110_KO.html) | 팀원의 R1.4 비교 결과와 개선 과정 |

공통 시뮬레이션과 합성은 `synth/rtl.f`에 등록된 `rtl/`의 EX판을 사용합니다. 보관 CORE를 시험할 때는 프로젝트 사본에서 `rtl/CORE.v`를 선택한 판으로 교체합니다. 위의 ID·단일 사이클 주기는 이전 실험값이므로 R1.7에서 기능과 STA를 다시 확인합니다. TOP과 CONTROLLER는 세 판에서 공통으로 사용합니다.

DICE 서버에서 이 폴더로 들어간 뒤 실행합니다.

```bash
python3.12 tools/check_release.py
bash run_sim.sh --program programs/int8_fastv2.hex && bash run_ppa.sh
```

`opt64v2`를 측정할 때는 `run_sim.sh`의 `--program` 경로를 `programs/int8_opt64v2.hex`로 바꿉니다. 다른 프로그램이나 주기로 실행하기 전에 기존 측정 결과를 따로 보관하세요. `--program`을 생략하면 수업 기준 프로그램이 선택됩니다.

실행이 완료되면 `results/ppa_summary.json`과 setup/hold를 확인합니다. `reports/cpu_hierarchy.rpt`에 TOP과 그 아래 CORE·CONTROLLER가 들어 있는지 확인하고, 같은 실행의 `results/TOP_mapped.ddc`를 최종 측정 결과와 함께 보관합니다. 1.62 ns에서 타이밍을 위반하면 `synth/common.sdc`의 주기 숫자만 조정하고 기능 실행부터 다시 진행합니다.

현재 `fastv2`와 `opt64v2`는 기본 8개 명령을 사용하며 선택 명령은 없습니다. 팀 제출 ZIP에는 최종 실행의 DDC·기능 로그·STA·면적·전력 보고서와 재현 자료, 발표 슬라이드 1부(PPTX 또는 PDF)를 포함합니다.

발표 초안 8쪽의 기준본 전력은 미측정입니다. 제출 전에 12쪽의 재현 명령과 18쪽의 제출 파일 목록을 R1.7에 맞추고, DICE에서 새로 측정한 수치를 반영합니다. 이전 실험 원본은 [팀 GitHub 커밋 `ffaa3cd`](https://github.com/ttkpark/DICE_Project/commit/ffaa3cd75b9272a143e9ec0c0d0af60c23005ebc)에 보관되어 있습니다. 최종 제출 ZIP을 만들 때는 이번 실행의 `results/`, `reports/`, `logs/`를 함께 넣습니다. 이 생성 폴더들은 Git에서 기본으로 제외됩니다.

교수님 배포 문서는 [릴리즈 노트](docs/RELEASE_NOTES_KO.md), [공통 실행 안내](docs/COMMON_FLOW_KO.md), [평가 계약](docs/PROJECT_CONTRACT_KO.md)에서 볼 수 있습니다. `MANIFEST.json`과 `RELEASE_VALIDATION.json`은 배포본 기록입니다.
