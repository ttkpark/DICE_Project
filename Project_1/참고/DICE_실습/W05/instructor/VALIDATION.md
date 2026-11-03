# W05 제작 검증 기록

검증일: 2026-09-22. 기준: W05exp.md 및 같은 날의 “todo 예제 내부도 학생이 작성” 추가 요청.

## 작성한 파일

- 학생 안내서 `README.md`와 `blank`, `todo`, `answer` 세 버전.
- 예제 1 DFF, 예제 2 nonblocking/blocking 비교, 예제 3 PC.
- PC TODO 6개 및 고정 11단계 체크포인트 TB.
- 각 예제·체크포인트의 상대경로 filelist, run/view 스크립트.
- 정답 해설, 조교 검사표, 예비보고서 문안, 본 검증 기록.

`todo`는 예제부터 미완성이며 완성 RTL은 `answer`에만 있습니다.
`blank`는 lesson과 checkpoint 모두 포트 껍데기로 제공합니다.
세 버전의 TB·filelist·스크립트는 동일합니다.
코드의 한글 설명은 유지하고 모든 파일·폴더 이름은 영어 ASCII로 작성했습니다.

## 실제 검증한 항목

Icarus Verilog의 `-g2001`로 컴파일·실행하고, 실제 Emacs verilog-auto로 배포 소스의
AUTOARG/AUTOINST를 생성했습니다. AUTO 재생성 후에도 네 검사 모두 통과했습니다.

| 로컬 검사 | 결과 |
|---|---|
| answer 예제 3개 + checkpoint | 컴파일 성공, 각 최종 PASS 1회 |
| untouched todo 예제 3개 + checkpoint | 모두 컴파일 성공, 기능 FAIL·비정상 종료, PASS 없음 |
| blank 예제 3개 + checkpoint | 모두 컴파일 성공, 미구현 출력에 대한 기능 FAIL |
| checkpoint TODO 6곳 각각 단독 미완성 | 6개 모두 컴파일 성공 후 FAIL |
| lesson PC TODO 6곳 각각 단독 미완성 | 6개 모두 컴파일 성공 후 FAIL |
| DFF 2곳, good 4곳, bad 4곳 각각 단독 미완성 | 10개 모두 컴파일 성공 후 FAIL |
| 동기 reset, PC+4 기준 분기, PCNext 직접 출력 | 각각 FAIL 검출 |
| PC 출력 X, Z | 각각 FAIL 검출 |
| 예제 offset=8 및 기대값 수정 | 0 → 4 → 8 → 16 → 20 통과 |
| TB 규칙 | task/function·무작위 입력·검사 반복문 없음, timeout 제공 |
| 파일·스크립트 | ASCII 이름, LF 줄바꿈, 상대경로, Bash 문법 확인 |

수업 서버의 실제 wrapper도 사용했습니다. 모의 실행이나 wrapper 이름을 대체한 검사가 아닙니다.

| 서버 검사 | 결과 |
|---|---|
| VCS V-2023.12-SP2-1 / DFF | W05 DFF PASS (8/8) |
| VCS / 두 단계 레지스터 | W05 PIPELINE PASS (6/6) |
| VCS / PC 예제 | W05 PC LESSON PASS (6/6) |
| VCS / checkpoint | W05 CHECKPOINT PASS (11/11) |
| vcs_queue --fsdb | DUMP_FSDB 설정 및 네 검사에서 새 VCD·FSDB 생성 확인 |
| 실행 위치 | 소스 폴더 밖에서 절대경로로 run 스크립트를 호출하여 성공 |
| 수정 전 TODO 예제 3개 + checkpoint | VCS에서도 컴파일 성공 후 기능 FAIL 확인 |
| 이전 PASS 결과가 있는 폴더에서 TODO 재실행 | 이전 성공 표시 제거, 실패 후 view 실행 거부 확인 |
| Verdi V-2023.12-SP2-6 | verdi_sub로 소스·FSDB 열기, 입력·PC·내부 후보 신호 8개 추가 성공 |

Verdi 검증은 Xvfb 가상 화면과 Tcl로 실제 프로그램을 실행했습니다.
사용자 데스크톱에서 마우스로 조작하는 과정이나 GUI 캡처를 검증한 것은 아닙니다.

배포 파일은 `W05.tar.gz` 하나입니다. 새 임시 폴더에 압축을 풀어 모든 파일의 바이트를 대조하고
동일한 로컬 기능·미완성 변형·AUTO 검사를 실행합니다. 소스·문서만 포함하며
build/logs, simv, 과거 파형·PASS 로그, 라이선스·서버 환경 파일은 포함하지 않습니다.

제작 도구와 원본 검증 로그는 작업 폴더의 `W05_tools` 및 `W05_validation`에 별도로 보관합니다.
검증 로그는 배포 아카이브에 포함하지 않습니다.

## 미검증 및 범위 밖 항목

- 학생 계정별 설치·배포 및 각 학생의 GUI 접속 환경.
- FPGA 보드 모델·핀 배치·합성·다운로드·실기 동작.
- 실제 소자의 setup/hold, reset 해제의 물리적 타이밍.
- 강의 PPT, GUI 캡처, 선택 FPGA 확장 모듈.

이 검사는 명시된 사례와 잘못된 구현을 검사한 결과이며 모든 32비트 입력의 완전 검증은 아닙니다.
`<=` 코딩 규칙은 단일 레지스터의 기능 검사만으로 강제하지 않고 조교가 소스로 확인합니다.
