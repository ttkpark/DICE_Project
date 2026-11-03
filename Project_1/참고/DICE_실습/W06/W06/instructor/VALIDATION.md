# W06 검증 기록

콘텐츠·서버 검증일: 2026-10-01. 학생 실행 파일을 간결한 명령어 목록으로 바꾸고 합성을 별도 레슨으로 분리했습니다. 2026-10-06 전체 계정 배포 도구와 안내를 추가했습니다.

## 현재 배포 구성

- lesson/01_ports, lesson/02_timing_x0: 시뮬레이션과 파형만 진행. 두 폴더의 synth는 제거했습니다.
- lesson/03_synthesis: 완성 REGFILE.v로 합성만 진행하는 별도 레슨.
- checkpoint: 기존 T1~T6·C01~C14와 정답 RTL 유지. 완성한 자기 RTL도 synth에서 합성 가능.
- run.sh: mkdir와 VCS 실행 두 명령. view.sh: Verdi 실행 한 명령.
- run_synth.sh: dc_shell_queue 한 명령. 자동 합성을 실행하지 않고 DC 프롬프트를 엽니다.
- synth.tcl: 환경·분석·조건·합성·저장·exit의 26개 명령. README와 같은 순서입니다.
- setup.tcl: 라이브러리·작업 폴더·WORK 준비만 수행합니다. 학생은 환경만 source합니다.
- library_setup.tcl: 실제 target/link library 설정 두 명령. if/foreach를 제거했습니다.

blank/todo/answer의 학생용 .sh/.tcl/.sdc에서 if/for/foreach/while/proc/catch, 해시 검사, 쉘 명령 치환과 조건 연결을 검사하여 없음을 확인합니다. RTL의 기능을 구현하는 Verilog if/for는 유지합니다. 복잡한 검사·배포 코드는 패키지 밖의 W06_tools에만 있습니다.

## 로컬 검사

Icarus Verilog 13.0의 Verilog-2001 모드, VVP, Emacs AUTO와 shell 구문 검사를 사용합니다. 로컬 검사 총 28개입니다.

- 세 버전의 완성 시뮬레이션 레슨 6개 PASS.
- answer 체크포인트 14/14 PASS, todo/blank 컴파일 후 C01 기능 실패.
- T1~T6 개별 변이와 추가 리셋·유지·bypass·X 변이 검출.
- 학생 변경 예제, Emacs AUTO 이후 실행 통과.
- 공통 파일 바이트 일치, filelist 독립성, ASCII/LF, TB 작성 규칙 확인.
- 문서 링크, 문서와 실제 synth.tcl 명령 일치, 기존 SDC 조건 유지 확인.
- 새 합성 레슨 RTL이 검증한 정답 RTL과 바이트 단위로 같음을 확인.
- 학생 스크립트의 제어문·해시 코드 부재 및 외부 도구 비정상 종료 상태 전달 확인.

배포 도구의 15개 검사는 임시 폴더에서 신규·반복 설치, 구버전 삭제, 다른 주차 유지, 실패 복구, 검증 실패 시 삭제 중단, 해시 불일치·심볼릭 링크·DC 자료 누락/빈 파일 거부를 확인합니다. 학생 홈은 변경하지 않습니다.

## 실제 서버 검사

계정 jhpark, 호스트 dice에서 기존 큐 wrapper를 사용합니다. VCS V-2023.12-SP2-1, Verdi V-2023.12-SP2-6, DC V-2023.12-SP5입니다.

- 단순화한 run.sh로 두 시뮬레이션 레슨과 answer 체크포인트를 실행하여 PASS와 새 FSDB/VCD 확인.
- todo/blank에서 컴파일 이후 예상한 FAIL C01을 확인.
- Verdi/Xvfb에서 세 FSDB와 아홉 포트 신호 로드 확인.
- checkpoint와 lesson/03_synthesis의 실제 명령 파일로 매핑과 결과 5개 저장 확인.

이 서버의 vcs_queue -R은 TB의 $fatal/FAIL 출력 뒤에도 종료 상태 0을 반환할 수 있습니다. 따라서 학생 안내는 방금 실행의 PASS/FAIL을 직접 읽게 합니다. 제작자 검증도 종료 상태만 보지 않고 실제 출력과 새 파형을 함께 판정합니다. 처음 서버 검사에서 이 차이를 발견해 검증 도구를 수정했으며 학생 코드에 조건문을 다시 넣지 않았습니다.

서버 검사 증거: W06_validation/latest/server. 최종 성공 로그와 결과만 남겼습니다. 로컬 28개 + 실제 서버 10개를 수행합니다.

## 실제 대화형 DC 검사

별도 합성 레슨과 answer 체크포인트의 새 복사본에서 실제 bash run_synth.sh를 실행했습니다. DC 프롬프트에 실제 synth.tcl의 26개 명령을 한 줄씩 입력하여 확인했습니다.

| 항목 | 결과 |
|---|---|
| 환경 설정 | source setup.tcl 성공, 실제 SAED32 RVT DB 로드 |
| 단위 | ns/fF |
| RTL 분석·연결 | analyze/elaborate/current_design/link/check_design 성공 |
| 조건 | 기존 SDC와 같은 10 ns, 입출력 min/max 0/1 ns, 입력 전이 0.1 ns, 출력 부하 20 fF |
| 합성 | compile 성공, check_design=1, is_mapped=true |
| 저장 | Verilog 넷리스트·DDC·SDC·면적·타이밍 보고서 5개 생성 |
| 종료 | exit=0과 큐 슬롯 반환 확인 |

증거: W06_validation/latest/lesson03 및 checkpoint. interactive.typescript에 입력·응답, verification.json에 명령별 결과·해시·실행 일시, exercise 아래에 실제 합성 결과와 보고서·파형을 보관합니다. 검증용 소스 복사본과 중간 빌드 파일은 삭제했습니다. 원본 로그 안의 실행 당시 경로는 수정하지 않았습니다. 체크포인트는 같은 검증 복사본의 단순화한 run.sh로 VCS 14/14 PASS도 확인했습니다.

TIM-134는 고 fanout 지연 추정, VO-4는 넷리스트의 assign/tran 출력에 관한 경고입니다. 결과를 검토했으며 Error/Fatal 없이 종료했습니다. 한 경로의 MET이나 is_mapped=true는 기능 등가성 또는 전체 타이밍 검증을 뜻하지 않습니다.

## 배포와 확인 범위

package.py로 만든 W06.tar.gz를 새 임시 폴더에 풀어 로컬 28개 검사를 수행합니다. 학생 압축에는 과거 로그·파형·PASS 마커·캐시·DB를 넣지 않습니다. 2026-10-01 작업 폴더의 이전 W06 백업·검증 폴더를 삭제하고 W06_validation/latest에 성공 증거를 남겼습니다.

2026-10-06 추가한 deploy_w06_all.sh는 실행 시 존재하는 diceNNN 전체 계정에 설치합니다. 기존 학생 작업은 /var/backups/dice-w06/deploy_*/계정명/W06에 보존하며, 다른 주차와 기존 검증 폴더는 유지합니다. 전체 경로를 사전 검사하고 계정별 파일 해시·읽기/쓰기/실행 권한을 확인합니다. 이 전체 배포 명령은 실제 계정의 VCS/Verdi/DC를 실행하지 않으며 server_validation은 not_run으로 기록합니다. 기존 deploy_w06_dice024.sh의 교체·서버 검증·구버전 삭제 동작은 dice024 한 계정에만 적용합니다.

실제 학생 계정의 설치·라이브러리 권한·대화형 동작은 교강사가 확인해야 합니다. 이번 수정에서 학생 홈을 직접 변경하지 않았습니다. 대표 주소 검사이며 전 주소 전수검증·합성 후 등가성·배치배선 이후 STA는 수행하지 않습니다.

## 제작자 재현 명령

```bash
python3 W06_tools/verify.py
python3 -m unittest discover -s W06_tools -p 'test_deploy*.py'
python3 W06_tools/verify.py --server --synthesis --output W06_validation/server_new
python3 W06_tools/verify_manual.py --lesson W06/todo/lesson/03_synthesis --output W06_validation/synthesis_new
python3 W06_tools/verify_manual.py --checkpoint W06/answer/checkpoint --output W06_validation/checkpoint_new
python3 W06_tools/package.py
```

출력 경로는 존재하지 않는 새 폴더를 사용합니다. verify_manual.py의 pexpect는 제작 도구 의존성이며 학생에게 설치나 실행을 요구하지 않습니다.
