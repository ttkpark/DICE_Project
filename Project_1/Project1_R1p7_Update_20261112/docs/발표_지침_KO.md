# Project 1 발표 지침 모음

2026-11-12 정리, 2026-11-14 R1.7 작업 폴더 기준으로 갱신. 수업 자료에 흩어져 있는 발표·제출 관련 지침을 한곳에 모았다. 괄호 안이 원문 위치다.

- **명세 PDF**: [`Project1_INT8_PPA_Release1p4_KO_20261103.pdf`](Project1_INT8_PPA_Release1p4_KO_20261103.pdf)
- **계약서**: [`PROJECT_CONTRACT_KO.md`](PROJECT_CONTRACT_KO.md) (R1.5~R1.7 내용 포함)
- **R1.5 공지**: e-Campus 공지 "R1.5 어셈블러 업데이트 및 발표자료 제출 안내"와 ZIP 안 `R1p5_ISA_사용안내_KO.md`
- **R1.6 공지** (2026-11-12): e-Campus 공지 "[Project 1 R1.6] 전체 계층 DDC 제출 및 공통 합성 Tcl 업데이트". R1.7(2026-11-12)은 서버 Python 3.12·`vcd2saif` 경로 자동 설정. 둘 다 [`RELEASE_NOTES_KO.md`](RELEASE_NOTES_KO.md)
- **비교 주의사항**: [`PPA_비교_주의사항_KO.md`](PPA_비교_주의사항_KO.md)

만든 슬라이드는 [`../presentation/project1.pptx`](../presentation/project1.pptx)(PDF 같이 있음, 19장)이고, 제출본은 [`../submission/Project1_TEAM_ID.zip`](../submission/Project1_TEAM_ID.zip)(폴더 이름 `TEAM_ID`를 팀 번호로 바꿀 것)이다. 슬라이드 생성기는 `../presentation/build/` (`npm install` 후 `node build_deck.js ../project1.pptx apply_theme.js`, PDF는 Windows PowerPoint로 `export.ps1`).

## 1. 일정과 형식

| 항목 | 내용 | 출처 |
|---|---|---|
| 제출 마감 | 2026-11-17(화) 09:00, e-Campus 업로드 | HANDOVER, 분반 공지 |
| 발표 | 같은 날 수업 시간 | HANDOVER |
| 동료 평가(피어리뷰) 설문 | 같은 날 23:59까지 | HANDOVER |
| 제출 형식 | **12주차 발표 슬라이드 1부 (PPTX 또는 PDF)** | R1.5 공지, 계약서 "평가와 제출" |
| 제출 경로 예시 | `presentation/project1.pptx` (명세 PDF 24쪽의 `report/project1.pptx`를 R1.5에서 정정) | R1.5 공지 |
| 서술형 보고서 | 내지 않는다 | R1.5 공지 |
| **계층 DDC** | `results/TOP_mapped.ddc` **필수**. 최종 PPA를 잰 그 실행에서 나온 DDC와 측정 결과를 함께 낸다. `reports/cpu_hierarchy.rpt` 로 TOP·CORE·CONTROLLER 계층 확인 | R1.6 공지, 계약서 |
| 발표 슬라이드와 기존 검증 자료 | 함께 제출 | R1.6 공지 |
| 발표 시간, 피어리뷰 양식 | **자료에 없다.** "세부 양식과 집계 방식은 수업 공지에서 안내" | 계약서 "발표 피어리뷰 10점" |

## 2. 배점에서 발표가 차지하는 자리

- 프로젝트 1 = PPA 25점 + 발표 피어리뷰 10점. 둘은 따로 매긴다 (명세 PDF 10·13·14쪽).
- 1주차 성적표 기준으로 프로젝트 명세 50점, 피어리뷰 20점이고, 프로젝트 1과 2가 같은 배점이다 (명세 PDF 14쪽, 계약서).
- **피어리뷰는 PPA 수치를 다시 채점하지 않는다.** 숫자가 높고 낮은지가 아니라 설계와 결과를 이해할 수 있게 설명했는지를 본다 (명세 PDF 14쪽, 계약서).
- 발표·질의응답은 PPA PASS/FAIL 관문과 분리된다 (계약서).

## 3. 피어리뷰 평가 요소 6가지와 우리 슬라이드

명세 PDF 14쪽 표 원문(자료 / 동료가 확인할 내용)을 그대로 옮기고, 각 요소를 다룬 슬라이드를 붙였다. "자료·시연·답변을 근거로 평가"한다.

| # | 평가 요소 | 근거 자료 | 동료가 확인할 내용 | 우리 슬라이드 |
|---|---|---|---|---|
| ① | 설계 이해 | 구조도 | 고정 인터페이스와 제어 흐름 설명 | 4 구조도, 5 제어 흐름 표 |
| ② | 기능 증거 | 로그 | Y·DONE 결과와 검사 범위 설명 | 11 서버 로그 + 검사 범위 표 |
| ③ | PPA 비교 | 표 | 같은 조건의 기준본·개선본 T/A/P | 8 기준본 vs 개선본, 9 15개 조합, 부록 A |
| ④ | 개선 근거 | 코드 | 변경 이유와 성능·면적·전력 영향 | 6 프로그램 변경, 7 경로·RTL 개선, 부록 C |
| ⑤ | 재현 방법 | 절차 | 파일·명령·조건을 따라 실행 가능 | 12 재현 절차, 부록 B·D·E (E는 수업 명령만으로) |
| ⑥ | 질의응답 | 답변 | 구현의 한계와 trade-off 설명 | 10 트레이드오프, 13 한계와 예상 질문 |

계약서 원문 표현: "① 고정 인터페이스·제어 흐름에 대한 설계 설명, ② `Y`·`DONE`과 검사 범위를 보여주는 기능 증거, ③ 동일 조건에서 기준본과 개선본의 T/A/P 비교, ④ 코드 변경과 지표 변화의 연결, ⑤ 파일·명령·조건을 포함한 재현 절차, ⑥ 구현의 한계와 trade-off에 대한 질의응답."

## 4. 슬라이드에 반드시 들어갈 것

- **기준본과 개선본의 T/A/P 비교, 개선 이유, 재현 방법** (R1.5 공지, 계약서 "평가와 제출").
- **기준본 대비 변경 이유와 항목별 개선·손실 정리** (명세 PDF 24쪽 "설계 설명"). 좋아진 것만이 아니라 나빠진 항목도 적는다. 우리는 A +29.4%, P 증가를 슬라이드 8·10에 적었다.
- **사용한 선택 명령 목록**. 우리는 "없음 (기본 8개만)"이다 (R1.5 공지; 슬라이드 2, 부록 D).

## 5. 발표와 맞물린 PPA 관문 (FAIL이면 PPA 0점)

명세 PDF 11쪽. 발표 자료가 곧 이 관문의 근거가 된다.

| 관문 | 확인 내용 |
|---|---|
| 재실행 | 깨끗한 작업 폴더에서 같은 결과를 다시 만든다 |
| 개선 근거 | 변경 전후 T/A/P 비교와 소스·로그가 일치한다 |

계약서 원문: "개선 근거는 동일 조건의 변경 전후 T/A/P와 소스·로그로 재현 가능해야 한다."
**그래서 기준본 P를 서버에서 재야 한다** (7장).

## 6. 비교·표현 규칙

`PPA_비교_주의사항_KO.md`와 계약서에서 발표에 걸리는 것만 골랐다.

**측정 조건 (주의사항 "측정 조건" 1~8)**

1. 같은 CPU/TOP 인터페이스와 같은 메모리 계약을 쓴다.
2. 같은 합성 library·corner·입출력 제약을 쓴다.
3. 주기를 바꾸면 setup뿐 아니라 hold도 확인한다.
4. RESET 해제 후 유효한 DONE store까지의 실제 clock edge 수를 잰다.
5. 시간은 cycle 수 × 인정된 주기다. async delay를 따로 더하지 않는다.
6. 면적은 같은 합성 영역끼리 비교하고, 메모리 포함 여부와 중복 계상 여부를 밝힌다.
7. 전력은 같은 workload, 같은 activity 측정 방식으로 비교한다.
8. 에너지는 평균 전력 × 실행시간으로 따로 계산한다. 전력 감소와 에너지 감소를 구분한다.

**표현할 때**

- 기준본은 느린 **프로그램**일 뿐, 가장 크거나 느리거나 전력이 큰 **하드웨어**가 아니다. "기준 하드웨어보다 몇 배"라고 말하지 않는다 (주의사항 "기준본의 성격").
- 공개 16 case는 연습 결과다. 공식 성적은 숨김 포함 24 case로 따로 나온다 (계약서, 명세 PDF 28쪽).
- 메모리 정적 전력은 수업용 추정치이고 실측 누설전력이 아니다 (계약서).
- 상용 도구 결과는 서버에서 확인하고, 임의 수치로 대체하지 않는다 (명세 PDF 28쪽).
- 우리 쪽 규칙: 표 안 점수는 우리 행끼리만 비교한 값이라 점수로 말하지 않는다. R1.3a 이전 flow(`compile_ultra`, 옛 SDC)의 숫자(2.1 ns, 1.7 ns 등)는 섞지 않는다.

## 7. 제출물 구성

명세 PDF 24쪽 폴더 예시에 R1.5 정정과 R1.6 DDC를 반영했다.

```text
TEAM_ID/
  rtl/TOP.v  rtl/CORE.v  rtl/CONTROLLER.v
  asm/optimized.s  asm/optimized.hex  asm/optimized.lst
  synth/common.sdc  synth/rtl.f
  run/reproduce.sh
  results/simulation_manifest.json  results/ppa_summary.json
  results/TOP_mapped.ddc            ← R1.6 필수 (같은 실행)
  reports/cpu_hierarchy.rpt         ← R1.6
  reports/
  presentation/project1.pptx        ← R1.5 정정 (원래 report/project1.pptx)
```

**함께 낼 검증 자료** (계약서)

- TOP·CORE·CONTROLLER RTL과 수정한 CPU 내부 모듈
- 어셈블리 원본 `.s`, 재생성한 `.hex`·`.lst`
- 사용한 선택 RV32I 명령 목록과 단독 기능 시험 (우리는 해당 없음)
- 기능 로그, STA·CPU area·CPU power 도구 출력, 선언 주파수
- 실행 cycle과 load/store 횟수, 선택된 IMEM 용량, 재현 절차

**금지** (계약서): 예약 입력의 비영값에 의존하는 기능, 고정 포트 위반, 금지 명령 사용, 선언한 선택 명령의 오동작이 있으면 기능 점검 실패다.

## 8. 개선 실험을 설명할 때의 원칙

명세 PDF 23쪽.

- **한 번에 한 변경**을 적용해 이득과 비용을 비교한다. 우리 슬라이드 3·8은 프로그램만 바꾼 단계와 CPU만 바꾼 단계로 나눴다.
- 루프 전개는 IMEM HEX word 수가 늘어나는지 따로 확인한다. `int8_fastv2`는 193 word라 256 구간이다.
- 선택 RV32I를 쓰면 표준 의미 확인, 단독 시험, 사용 명령 목록 제출이 필요하다.
- 공통 제한: 정답 lookup이나 입력 특화 동작은 금지하고, Y와 완료 계약을 유지한다.

## 9. 발표 전에 남은 일

| 할 일 | 이유 | 방법 |
|---|---|---|
| **기준본 P를 서버에서 잰다** | 슬라이드 8의 "서버 측정 예정" 칸. 피어리뷰 ③과 관문 "개선 근거"에 필요 | 아래 설정 참고. 측정 후 `presentation/build/build_deck.js`의 `BASE_P`에 숫자를 넣고 다시 생성 |
| ~~R1.7로 `int8_fastv2`(최종)·`int8_opt64v2` 서버 측정~~ **완료 (2026-11-14)** | 16/16 PASS, timing PASS. fastv2: T 1.021005 µs · A 100342.97 µm² · P 15.4104 mW (R1.4·R1.6 값과 같음), DDC 416 KB, 계층 TOP > CORE > CONTROLLER | [`../measurements/R1p7_20261114/`](../measurements/R1p7_20261114/README.md), 제출본은 그 fastv2 실행으로 만들었다 |
| 발표 시간과 피어리뷰 양식을 확인한다 | 자료에 없다 | 분반 공지 또는 조교 |
| 발표자 나누기 | — | 슬라이드마다 발표자 노트(대본)를 넣어 두었다 |

**기준본 P 측정 방법** (R1.7 작업 폴더, 서버)

같은 조건 비교를 위해 단일 사이클 CPU(`archive/single_cycle/CORE.v`, 지난 비교 실험과 바이트 동일)와 주기 3.82 ns로 배포 기준 프로그램을 잰다. 최종 측정 결과를 덮어쓰지 않게 사본 폴더에서 한다.

```bash
cd ~/DICE_Project/Project_1
cp -r Project1_R1p7_Update_20261112 p1_baseline && cd p1_baseline
rm -rf build logs reports results
cp archive/single_cycle/CORE.v rtl/CORE.v
sed -i -E 's/(-period )[0-9.]+/\13.82/' synth/common.sdc && grep create_clock synth/common.sdc
bash run_sim.sh --program baseline_int8_fc_slow.hex && bash run_ppa.sh
grep -E '"(mean_cycles|time_us|total_area_um2|total_power_mw)"' results/ppa_summary.json
```

- 기준본 HEX는 작업 폴더 루트에 있어서 `programs/`가 붙지 않는다.
- 기준본은 case당 cycle이 길어(평균 8,136) VCD가 크고 오래 걸린다.
- 주기는 단일 사이클 행과 같은 3.82 ns로 잰다. 그래야 CPU·SDC가 같고 프로그램만 다른 "같은 조건" 비교가 된다. 면적은 같은 합성 결과라 77,533.67 µm²가 나와야 한다.
