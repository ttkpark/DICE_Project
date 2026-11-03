# W07 검증 기록

## 2026-10-13 TODO 전체 제어값 개정 — 로컬 검사 47개 통과

현재 TODO는 기본값 9곳·명령별 제어값 28곳·PCSRC 1곳, 총 38곳의 우변을 모두 비트 폭에 맞는 0으로 통일했습니다. ILLEGAL 기본값도 학생이 작성합니다. 체크포인트는 T0–T9이며, 정답이 0인 16곳은 확인 후 유지하고 나머지 22곳의 값·식을 수정합니다. 명령어 판별 구조, answer/blank, 공통 TB·wrapper·실행 파일은 유지했습니다.

`python3 W07_tools/verify.py --output W07_validation/local_all_zero`로 새 임시 복사본에서 확인했습니다.

- answer: CONTROL PASS (16/16).
- todo: Verilog-2005 컴파일 성공, C01–C16 모두 예상 FAIL (0/16 PASS).
- blank: 기존과 같이 지원 명령 11개 FAIL, invalid 5개 PASS.
- 대입 38곳 모두 0이며 각 TODO 표시와 명령어 판별 구조가 유지됨을 확인.
- 정답에서 대입 38곳을 각각 하나씩 오답으로 바꿔 고정 TB의 해당 검사 실패 확인. 정답이 0인 곳도 1로 바꿔 검출 확인.
- 추가 명령어 경계 조건·wrapper 지연·Emacs AUTO, 문서 링크·공통 파일·실행 명령 일치 등 총 47개 검사 통과.

증거: `W07_validation/local_all_zero/verification.json`과 같은 폴더의 실제 로그. 이번 개정의 서버 VCS/Verdi/DC 검사는 수행하지 않았습니다. 아래 서버 기록은 2026-10-06의 이전 TODO 버전에 대한 결과입니다.

## 2026-10-06 초기 버전 검증 이력

실제 서버 dice의 제작자 계정에서 새 복사본으로 실행했습니다. 최종 서버 실행: 2026-10-06T20:16:07.787765+09:00 ~ 2026-10-06T20:16:29.051288+09:00. 아래 제공 자료·로컬 검사·서버 검사·타이밍 결과는 모두 초기 T1–T6 버전의 이력입니다.

## 제공 자료

W07exp.md를 구현한 answer/todo/blank, 공통 고정 TB, 타이밍 관찰 wrapper, 직접 실행하는 학생 안내, T1–T6 체크포인트, 교수자 답안입니다. 학생 셸/Tcl 파일에는 조건문·반복문·함수·해시 검사 없이 명령만 순서대로 있습니다. run_synth.sh는 대화형 DC만 열며, setup.tcl은 환경만 준비합니다.

## 명세에서 바로잡은 부분

1. 현재 DC V-2023.12-SP5에서 `report_timing -from [all_registers] -to [all_registers]`는 register cell을 받지 못하고 UID-119/UID-445/CMD-036 오류를 보고서에 기록했습니다. 서버의 `man all_registers`/`man report_timing`으로 확인하여 출발은 `all_registers -output_pins`, 도착은 `all_registers -data_pins`로 수정했습니다. 학생 안내, 세 synth.tcl, W07exp.md에 동일하게 반영했습니다.
2. 상수 대입만 있는 blank의 `always @*`는 감도 목록이 비어 초기 기본값도 평가되지 않습니다. blank만 `always @(INSTR or ZERO)`를 사용하여 미완성 상태도 안전 기본값을 냅니다. 완성 조합논리에서는 `always @*`를 사용합니다.
3. wrapper의 AUTOINST만 갱신하면 instr_q/zero_q가 동명 외부 INSTR/ZERO에 다시 연결되어 입력 레지스터를 우회할 수 있습니다. AUTO_TEMPLATE로 두 연결을 고정하고 TB/wrapper에 상대 RTL 검색 경로를 추가했습니다. AUTO 갱신 뒤에도 실제 한 사이클 지연 검사를 통과했습니다.

## 로컬 검사 — 15개 통과

도구: Icarus Verilog version 13.0 (stable) (v13_0), VVP, Emacs verilog-mode. Verilog-2005 모드로 컴파일했습니다.

- answer: CONTROL PASS (16/16).
- todo: 컴파일 성공, C02/C03/C05/C06/C07/C08/C09/C10/C14 예상 실패.
- blank: 컴파일 성공, C01–C10/C14 예상 실패, invalid 5개 안전 기본값 통과.
- T1–T6을 정답에서 각각 하나씩 오답으로 바꿔 대응 검사 실패 확인.
- 추가 11개 입력: JAL immediate/funct3 영역과 ZERO=X, 음수 ADDI/LW/SW, 미지원 ANDI/SB/JALR/funct7, BEQ ZERO, invalid.
- 같은 추가 입력으로 launch edge에는 이전 결과, 다음 capture edge에는 새 결과가 나오는지 검사.
- Emacs AUTO 갱신 후 고정 TB 16/16과 wrapper 추가 11개 검사 통과.
- 공통 파일 일치, 독립 filelist, TODO 표현식 6곳만 차이, ASCII 파일명/UTF-8/LF, 문서 링크, 셸 문법, 학생 스크립트 단순성 확인.
- 학생 문서와 실제 VCS/Verdi 명령 및 DC 30개 명령 일치, compile 한 번 확인.

증거: `W07_validation/local_verified/verification.json`과 같은 폴더의 실제 로그.

## 실제 서버 검사

|도구|확인 버전|
|---|---|
|VCS|V-2023.12-SP2-1_Full64|
|Verdi|V-2023.12-SP2-6|
|Design Compiler|V-2023.12-SP5|
|Library|saed32rvt_tt1p05v25c, SAED32 RVT TT 1.05V 25°C|
|단위|Time_unit=1e-09 s (ns), Capacitive_load_unit=1e-15 F (fF)|

각 버전에서 실제 `bash run.sh`로 VCS를 실행했습니다. answer 16/16 PASS, todo/blank 예상 FAIL, 새 FSDB/VCD 생성을 확인했습니다. 이 서버 VCS -R은 $fatal 후에도 shell 상태 0이므로 로그 내용으로 판정했습니다. 실제 Verdi/Xvfb에서 정답 FSDB와 신호 10개를 로드했습니다.

DC는 실제 `bash run_synth.sh`로 열고 DC_STEP_BY_STEP_KO.md의 30개 명령을 프롬프트에 한 줄씩 입력했습니다. link/check_design=1, check_timing=1 및 경고 없음, is_mapped=true, clock 하나에 10ns→5ns 변경, compile 한 번, 네 register 경로 보고서, exit=0 및 큐 슬롯 반환을 확인했습니다.

check_design의 LINT-28은 decode에서 쓰지 않는 rs1/rs2/rd 비트, LINT-52/LINT-2는 항상 0인 ALUCTRL[2]/CTRL_Q[4]와 최적화된 연결에 대한 경고입니다. VO-4는 넷리스트에 assign/tran을 출력한다는 경고입니다. 해당 신호 계약과 넷리스트를 검토했고, 최종 실행에는 Error/Fatal이나 경로 누락이 없습니다. 경고를 임의로 숨기지 않았습니다.

## 실제 타이밍 결과

아래는 이번 서버 실행의 보고서 표시값이며 단위는 ns입니다. 학생의 절대 수치 정답으로 고정하지 않습니다.

|보고서|Startpoint|Endpoint|Arrival|Required|Slack|결과|
|---|---|---|---:|---:|---:|---|
|setup_10ns|instr_q_reg[4]|CTRL_Q_reg[1]|0.48|9.97|9.49|MET|
|setup_5ns|instr_q_reg[4]|CTRL_Q_reg[1]|0.48|4.97|4.49|MET|
|hold_10ns|zero_q_reg|CTRL_Q_reg[1]|0.13|-0.01|0.14|MET|
|hold_5ns|zero_q_reg|CTRL_Q_reg[1]|0.13|-0.01|0.14|MET|

같은 mapped netlist와 같은 경로에서 setup arrival은 유지되고 required/slack은 정확히 5ns 감소했습니다. same-edge hold는 주기를 바꿔도 그대로였습니다. 이 회로에서는 네 보고서 모두 MET이며, 5ns 위반을 만들기 위해 조건을 조작하지 않았습니다.

최종 증거는 `W07_validation/server_final/verification.json`, `interactive.typescript`, `vcs_answer.log`, `vcs_todo.log`, `vcs_blank.log`, `verdi.log`에 있습니다. 실제 예비 보고서는 `W07_validation/server_final/answer/synth/reports`, 넷리스트와 SDC는 그 옆 `results`에 보관했습니다. 수정 전 DC 경로 명령의 실패 기록은 `W07_validation/server`에 남겼습니다.

최종 서버 검증 JSON에 실행한 학생 소스 30개와 안내의 SHA256을 기록했습니다. 검증 원본과 배포 소스의 일치를 확인했습니다. 대형 빌드 캐시는 배포하지 않습니다.

## 배포 파일과 범위

`W07_tools/package.py`는 W07/ 한 루트의 `W07.tar.gz`와 `W07.tar.gz.sha256`을 만듭니다. 현재 개정본은 압축을 새 임시 폴더에 풀어 로컬 47개 검사를 통과해야 최종 파일로 저장합니다. 재검증 로그·파일 목록·해시는 `W07_validation/archive_verification.log`, `archive_manifest.txt`, `archive_sha256.txt`에 기록합니다.

압축에는 answer/todo/blank와 이 교수자 문서를 포함합니다. DB/라이선스, 파형, 빌드 캐시, 서버 로그, 제작자 도구는 제외합니다. 실제 예비 보고서는 위 검증 폴더에서 별도로 사용합니다.

학생 계정 설치는 수행하지 않았습니다. 대표 제작자 계정의 기능/파형/합성 단계 검증이며, 전체 ISA 전수 검사·합성 후 등가성·배치배선 이후 signoff가 아닙니다. 각 학생 계정의 DB 접근 권한과 GUI 연결은 수업 전에 확인합니다.

[학생 실행 안내](../README_KO.md) · [DC 한 줄 실행](../DC_STEP_BY_STEP_KO.md)
