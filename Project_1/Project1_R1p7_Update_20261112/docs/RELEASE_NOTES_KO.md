# EE362 Project 1 릴리즈 노트

## R1.7 · 2026-11-12 · DICE 실행 환경 자동 설정

- `run_sim.sh`와 `run_ppa.sh`는 DICE에 설치된 `/usr/bin/python3.12`를 사용합니다. 서버의 기본 `python3`는 3.6이므로 경로를 고정했습니다.
- `run_ppa.sh`가 Synopsys V-2023.12-SP5의 `vcd2saif` 경로를 이번 실행에만 설정합니다. 로그인 설정 파일 편집이나 수동 `export PATH` 없이 실행합니다.
- `run_sim.sh --program optimized.hex` 형식으로 팀의 최종 HEX를 지정합니다. `run_ppa.sh`는 직전 시뮬레이션의 프로그램과 activity를 사용합니다.
- R1.7 ZIP은 R1.5 어셈블러와 R1.6 전체 계층 DDC 합성 Tcl을 포함합니다. R1.4 프로젝트 폴더에 R1.7 ZIP을 적용하면 됩니다. 제출할 전체 계층 DDC는 `results/TOP_mapped.ddc`입니다.

```bash
# 업데이트 ZIP을 프로젝트 폴더의 상위 폴더에 내려받은 경우
unzip -o ../Project1_R1p7_Update_20261112.zip
# optimized.hex를 팀의 실제 최종 HEX 파일명으로 바꾸어 실행
bash run_sim.sh --program optimized.hex
bash run_ppa.sh
ls -lh results/TOP_mapped.ddc
cat reports/cpu_hierarchy.rpt
```

DICE 기본 로그인 환경에서 검증용 CPU로 실행했습니다. 최종 HEX 지정, 공개 VCS 케이스 16개, SAIF 변환, PPA, 새 Design Compiler 세션에서의 DDC 재열기 및 전체 계층 일치까지 확인했습니다.

## R1.6 · 2026-11-12 · 전체 계층 DDC 제출

- 팀 제출 ZIP의 `results/TOP_mapped.ddc`에 최종 PPA 측정에 사용한 mapped `TOP`과 그 아래 합성 CPU 계층을 담습니다. `CORE`, `CONTROLLER`, 팀이 실제로 인스턴스한 하위 CPU 모듈을 포함합니다. 외부 IMEM/DMEM과 테스트벤치는 기존 CPU 합성 범위에서 제외됩니다.
- 공통 `synth/run_ppa.tcl`은 합성 전에 CPU 모듈 경계의 ungroup을 막고, 합성 직후 `write_file -format ddc -hierarchy`로 DDC를 저장합니다. 계층 확인용 `reports/cpu_hierarchy.rpt`도 생성합니다. 새 DDC가 없거나 빈 파일이면 PPA 실행을 중단합니다.
- R1.6 ZIP은 R1.5의 허용 명령 37개 지원과 발표 슬라이드 제출 안내를 포함하는 누적 업데이트입니다. 기존 R1.4 프로젝트에 R1.6 ZIP 하나를 적용합니다. 팀 RTL, 프로그램, 공통 SDC는 ZIP에 포함되지 않습니다.
- 업데이트한 Tcl이 공통 실행의 재현 확인 대상이므로, 팀의 최종 HEX로 sim → PPA 순서로 다시 실행합니다. DDC와 측정 결과는 같은 실행에서 생성된 파일을 제출합니다. 제출 일정과 배점은 기존 과제 공지를 따릅니다.

```bash
# 업데이트 ZIP을 프로젝트 폴더의 상위 폴더에 내려받은 경우
unzip -o ../Project1_R1p6_Update_20261112.zip
# 실제 제출 프로그램의 HEX 파일명을 지정
python3 tools/run_flow.py sim --program optimized.hex
bash run_ppa.sh
# DDC가 생성됐는지, 합성 계층이 맞는지 확인
ls -lh results/TOP_mapped.ddc
cat reports/cpu_hierarchy.rpt
```

DICE 서버의 Design Compiler V-2023.12-SP5에서 배포 Tcl로 DDC를 생성하고, 새 세션에서 다시 열어 합성 직후의 전체 계층 리포트와 일치함을 확인했습니다. [Synopsys Design Compiler User Guide, Saving Designs](https://iccircle.com/static/upload/img20240324171107.pdf#page=184)

## R1.5 · 2026-11-12 · 어셈블리 도구 및 제출 안내

- Python 어셈블러와 공개 기능 모델이 `BNE`를 포함한 Harris 부록 B 표 B.1의 허용 명령 37개를 지원합니다. 기본 8개는 필수이며 선택 명령을 사용한 팀은 해당 RTL 동작과 단독 기능 시험을 제출합니다.
- 설계 설명은 12주차 발표 슬라이드 1부(PPTX 또는 PDF)에 정리합니다. 기능·STA·면적·전력 도구 출력과 재현 자료를 함께 제출합니다.

## R1.4 · 2026-11-03 · 기본 배포본

## 이번 변경의 이유

R1.3a는 CPU-only 합성을 요구하면서 TOP 안에 `$readmemh` 기반 IMEM/DMEM을 포함했고, 공통 SDC는 TOP 포트를 기준으로 작성되어 합성 경계가 맞지 않았음. 안내문이 참조한 공통 합성·전력 측정 스크립트도 누락. R1.4에서 함께 수정.

## R1.4 변경 사항

| 항목 | R1.3a | R1.4 |
|---|---|---|
| CPU 합성 경계 | TOP 안에 IMEM/DMEM | TOP에는 CORE만, 메모리는 TB_TOP에서 연결 |
| TOP INSTR | 출력 32비트 | 입력 32비트로 변경 |
| TOP READDATA | 외부 포트 없음 | 입력 32비트 추가 |
| 메모리 위치 | rtl/ | sim/mem/ |
| SDC 입력 | RESERVED_IN*만 | INSTR, READDATA, RESERVED_IN* 모두 min=max 1.00ns |
| 공통 실행 | 안내만 존재 | run_sim.sh / run_ppa.sh / tools/run_flow.py / synth/run_ppa.tcl 제공 |
| 활동 측정 | 공통 절차 누락 | reset 후 DONE까지 case별 CPU activity와 주기·소스 일치 검사 |

## 기존 구현 이행

1. TOP의 `INSTR` 방향을 입력으로 변경하고 `READDATA` 입력 추가.
2. CORE의 `.INSTR(INSTR)`, `.READDATA(READDATA)` 연결. TOP 안의 IMEM/DMEM 제거.
3. 메모리는 제공 `sim/TB_TOP.v`의 연결 사용. TB 수정·black box 작성 불필요.
4. `synth/rtl.f`에 실제 CPU 파일만 등록. IMEM/DMEM/TB/MEMORY_POWER 및 simulation interpreter 제외.
5. R1.4 SDC와 TB로 재컴파일·기능 실행·PPA 다시 측정. 이전 VCD/SAIF·보고서 혼용 금지.

## 변경하지 않은 조건

- CORE/CONTROLLER 포트, 예약 입력·출력 각 20개, 예약 입력 0·출력 미연결.
- RESET 동기 active-high. 합성 후 정상 모드 STA에서만 RESET=0 case analysis.
- 기본 8명령 필수, Harris RV32I 선택 확장 허용, MUL 포함 M 확장 금지.
- INT8 계산·메모리 주소·Y/DONE 계약, SRAM 비용 산식, PPA 25점(2:1:1)·발표 피어리뷰 10점.
- 분반별 제출·발표 일정은 e-Campus 공지대로 유지.

## 검증 기록의 범위

로컬 검증: Verilog-2001 컴파일, 새 TOP/TB 메모리 경계 및 포트 연결, 별도 검사 구현으로 공개 16개 회귀, SDC 포트 적용 및 스크립트 정적 검사. 자세한 기록은 `RELEASE_VALIDATION.json`.
이 PC에는 서버용 DC·VCS와 SAED32 library/license가 없으므로 상용 도구 합성·power 수치는 생성하지 않았음. 배포 스크립트는 누락·불일치에서 중단하며 vectorless 전력을 실제 측정값으로 대신 쓰지 않음. 서버에서 오류 발생 시 전체 logs/reports와 버전을 조교에게 전달.

## 버전 이력

- R1.4 / 2026-11-03: CPU-only 경계, TOP 포트, SDC, 공통 실행 스크립트 동시 개정.
- R1.3a / 2026-10-23: 변수 없는 고정 숫자 SDC. clock period만 팀별 변경.
- R1.3 / 2026-10-23: I/O min=max 1ns, 동기 active-high reset, compile 후 정상 STA case analysis.
- R1.2 / 2026-10-20: PPA 25점·발표 10점.
- R1.1 / 2026-10-20: 예약 포트 20개씩, SRAM 비용·상대평가 계약.

파일명에 버전과 날짜를 표시합니다. MANIFEST.json은 R1.4 기본 ZIP의 파일을 확인하는 기록입니다. 최신 제출에는 R1.7 실행 스크립트와 이 ZIP에 포함된 R1.6 공통 합성 Tcl을 적용합니다.
