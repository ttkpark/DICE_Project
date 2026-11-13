# 팀 EX 작업본 · R1.7

## 현재 상태 (2026-11-14, 박기호)

- **R1.7 서버 측정 완료.** 이 폴더를 DICE에서 그대로 돌렸다(`int8_opt64v2` 먼저, `int8_fastv2` 마지막). 결과·명령·요약: [`measurements/R1p7_20261114/`](measurements/R1p7_20261114/README.md)
  - `int8_fastv2` (최종): 16/16 PASS, timing PASS (setup +0.0026 ns), T 1.021005 µs, A 100342.97 µm², P 15.4104 mW, DDC 416 KB, 계층 TOP > CORE > CONTROLLER
  - `int8_opt64v2`: 16/16 PASS, T 1.2589 µs, A 81704.17 µm², P 11.8581 mW
  - 두 값 모두 R1.4·R1.6 측정과 끝자리까지 같다.
- **제출본:** [`submission/Project1_TEAM_ID.zip`](submission/Project1_TEAM_ID.zip) — 위 `int8_fastv2` 실행의 results·reports·logs·DDC + RTL·asm·SDC·도구·재현 스크립트·발표 슬라이드. 안의 `TEAM_ID` 폴더 이름만 팀 번호로 바꿔 다시 묶는다.
- **발표:** [`presentation/project1.pptx`](presentation/project1.pptx) / `.pdf` 19장 (R1.7 명령·fingerprint 반영, 부록 E는 수업 명령만으로 재현). 다시 만들기: `cd presentation/build && npm install && node build_deck.js ../project1.pptx apply_theme.js` (PDF는 Windows PowerPoint에서 `powershell -File export.ps1 -Pptx ..\project1.pptx -Pdf <절대경로>\project1.pdf`)
- **문서:** [팀 실험 정리 HTML](docs/PRESENTATION_1110_KO.html)에 "최종 실행·제출본", "서버에서 재현하기"(공식 2줄 판 + 수업 명령만으로 하는 판) 추가. [발표 지침](docs/발표_지침_KO.md), [통합 컨텍스트](docs/PROJECT1_CONTEXT_KO.md)(옛 자료 링크는 커밋 `ffaa3cd`).
- **남은 일:** ① 제출 ZIP의 `TEAM_ID` → 팀 번호, ② 기준본 P 서버 측정(슬라이드 8 빈칸, 명령은 [발표 지침 §9](docs/발표_지침_KO.md)), ③ 발표 시간·피어리뷰 양식 확인. 마감 11-17(화) 09:00.
- Windows에서 작업할 때: 저장소 루트 `.gitattributes`가 스크립트·RTL·HEX를 LF로 고정한다. 서버에는 `git clone`이나 GitHub ZIP으로 옮긴다.

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
| [발표 PPTX](presentation/project1.pptx) | 발표 슬라이드 19장 (PDF 같이 있음, 생성기 `presentation/build/`) |
| [팀 실험 정리 HTML](docs/PRESENTATION_1110_KO.html) | R1.4 비교 결과·개선 과정, R1.7 최종 실행·제출본, 서버 재현 절차 |
| `measurements/R1p7_20261114/` | R1.7 서버 측정 기록 (fastv2·opt64v2의 results·reports·logs) |
| `submission/Project1_TEAM_ID.zip` | 제출본 |

공통 시뮬레이션과 합성은 `synth/rtl.f`에 등록된 `rtl/`의 EX판을 사용합니다. 보관 CORE를 시험할 때는 프로젝트 사본에서 `rtl/CORE.v`를 선택한 판으로 교체합니다. 위의 ID·단일 사이클 주기는 이전 실험값이므로 R1.7에서 기능과 STA를 다시 확인합니다. TOP과 CONTROLLER는 세 판에서 공통으로 사용합니다.

DICE 서버에서 이 폴더로 들어간 뒤 실행합니다.

```bash
python3.12 tools/check_release.py
bash run_sim.sh --program programs/int8_fastv2.hex && bash run_ppa.sh
```

`opt64v2`를 측정할 때는 `run_sim.sh`의 `--program` 경로를 `programs/int8_opt64v2.hex`로 바꿉니다. 다른 프로그램이나 주기로 실행하기 전에 기존 측정 결과를 따로 보관하세요. `--program`을 생략하면 수업 기준 프로그램이 선택됩니다.

실행이 완료되면 `results/ppa_summary.json`과 setup/hold를 확인합니다. `reports/cpu_hierarchy.rpt`에 TOP과 그 아래 CORE·CONTROLLER가 들어 있는지 확인하고, 같은 실행의 `results/TOP_mapped.ddc`를 최종 측정 결과와 함께 보관합니다. 1.62 ns에서 타이밍을 위반하면 `synth/common.sdc`의 주기 숫자만 조정하고 기능 실행부터 다시 진행합니다.

현재 `fastv2`와 `opt64v2`는 기본 8개 명령을 사용하며 선택 명령은 없습니다. 팀 제출 ZIP에는 최종 실행의 DDC·기능 로그·STA·면적·전력 보고서와 재현 자료, 발표 슬라이드 1부(PPTX 또는 PDF)를 포함합니다.

발표 8쪽의 기준본 전력은 아직 미측정입니다. 12쪽 재현 명령과 18쪽 제출 파일 목록은 R1.7 기준으로 맞췄고, 수치는 2026-11-14 R1.7 측정과 같습니다. 이전 실험 원본은 [팀 GitHub 커밋 `ffaa3cd`](https://github.com/ttkpark/DICE_Project/commit/ffaa3cd75b9272a143e9ec0c0d0af60c23005ebc)에 보관되어 있습니다. 최종 제출 ZIP을 만들 때는 이번 실행의 `results/`, `reports/`, `logs/`를 함께 넣습니다. 이 생성 폴더들은 Git에서 기본으로 제외됩니다.

교수님 배포 문서는 [릴리즈 노트](docs/RELEASE_NOTES_KO.md), [공통 실행 안내](docs/COMMON_FLOW_KO.md), [평가 계약](docs/PROJECT_CONTRACT_KO.md)에서 볼 수 있습니다. `MANIFEST.json`과 `RELEASE_VALIDATION.json`은 배포본 기록입니다.
