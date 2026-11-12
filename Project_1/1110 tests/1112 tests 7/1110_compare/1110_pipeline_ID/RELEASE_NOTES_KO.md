# EE362 Project 1 - Release 1.4 (2026-11-03)

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

파일명에 버전·날짜를 표시하고 MANIFEST.json의 SHA-256으로 동일 배포본 여부 확인. 이전 버전은 이행 참고용이며 새 제출은 R1.4 포트·TB·SDC로 통일.
