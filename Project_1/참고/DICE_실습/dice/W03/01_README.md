> 실행 도구 변경: 기존 회로·문제는 그대로입니다. 아래 run 스크립트로 VCS 검사 후 view 스크립트로 FSDB 파형을 봅니다. 이전 Icarus 재검사 안내는 사용하지 않습니다.

# EE362 3주차 실험 예제

**처음 배우는 학생은 [처음부터 따라 하기](00_START_HERE.md)를 먼저 읽으세요.**
이 README는 전체 명령과 규격을 찾아보는 참고 자료입니다.

`always @(*)`로 조합회로를 작성하고, 진리표와 시뮬레이션으로 결과를 확인합니다.
기본 진입점은 **todo**입니다. answer를 열어 참고하면서 작성해도 됩니다.

| 폴더 | 제공 내용 |
|---|---|
| blank | 정답 대상 RTL은 빈 파일, 완성 TB와 관찰용 BAD 제공 |
| todo | 문법이 유효한 임시 코드와 번호가 있는 TODO, 완성 TB |
| answer | 블록 내부 정답과 해결 번호, 완성 TB |

파일 앞의 01~10은 실습 순서입니다. 전체 열기 순서는 `00_START_HERE.md`에 있습니다.
세 폴더의 경로·모듈·포트·TB는 같습니다. **TOP 연결은 학생 과제이므로 answer에도 TODO만 있습니다.**
blank의 빈 RTL은 작성 전 컴파일되지 않습니다. todo는 컴파일되지만 모든 TB에서 FAIL하는 것이 정상입니다.
answer는 수업 예제 3개와 검사 블록 3개에서 PASS, TOP은 연결 전 FAIL입니다.
관찰용 BAD 원본은 보존하고 `06_mux_fixed.v`를 수정하세요. BAD 출력은 FIXED 합격 판정에 포함하지 않습니다.

## 30분 수업

| 시간 | 학생이 직접 할 일 | 실습하면서 설명할 개념 | 확인 결과 |
|---|---|---|---|
| 0~5분 | MUX 정답 따라 쓰기, S 변경, 시뮬레이션 실행 | 입력 변화에 반응하는 `always @(*)`, `begin/end`, `reg`, 대입 `=` | S=0이면 A, S=1이면 B 선택 |
| 5~13분 | 2→4 디코더 진리표를 `if/else`와 `case`로 각각 작성 | 조건에 따른 출력 선택, 표의 각 행과 코드의 대응 | 입력 네 가지에서 두 구현의 출력 일치 |
| 13~19분 | 감도 목록이 잘못된 MUX 실행 후 수정 | 읽는 입력을 감도 목록에서 빠뜨렸을 때의 시뮬레이션 오류 | S를 고정하고 B만 바꿔도 출력 갱신 |
| 19~25분 | `else`가 없는 MUX 실행 후 수정 | 모든 경로에서 출력 대입, 이전 값 유지와 래치 | S=0으로 바꿨을 때 A 출력 |
| 25~30분 | TODO 잔여 항목 확인, 수정한 코드 재실행 | 조합회로 작성 규칙 정리 | 두 오류를 재현하고 수정 후 PASS 확인 |

30분에는 BCD 변환기·FPGA 업로드까지 넣지 않음. 수업 후 검사 과제로 분리하여 학생별 진행 속도 확보.

## 파일과 포트 규격

각 폴더에 `lesson/rtl`, `lesson/tb`, `checkpoint/rtl`, `checkpoint/tb` 및 각 영역의 `build`, `logs`가 있습니다.
blank에서 작성할 때도 아래 대소문자와 신호 폭을 그대로 사용하세요.

| 영역/파일 | 모듈 | 입력 (wire) | 출력 |
|---|---|---|---|
| lesson/rtl/01_mux2.v | MUX2 | A, B, S (각 1비트) | reg Y |
| lesson/rtl/02_dec2_if.v | DEC2_IF | SEL[1:0] | reg [3:0] Y |
| lesson/rtl/03_dec2_case.v | DEC2_CASE | SEL[1:0] | reg [3:0] Y |
| lesson/rtl/04_mux_bad_sensitivity.v | MUX_BAD_SENSITIVITY | A, B, S | reg Y |
| lesson/rtl/05_mux_bad_assignment.v | MUX_BAD_ASSIGNMENT | A, B, S | reg Y |
| lesson/rtl/06_mux_fixed.v | MUX_FIXED | A, B, S | reg Y |
| checkpoint/rtl/07_add4.v | ADD4 | A[3:0], B[3:0] | reg [4:0] SUM |
| checkpoint/rtl/08_bin5_to_bcd.v | BIN5_TO_BCD | BIN[4:0] | reg [3:0] TENS, ONES |
| checkpoint/rtl/09_bcd_to_7seg.v | BCD_TO_7SEG | BCD[3:0] | reg [6:0] SEG |
| checkpoint/rtl/10_w03_top.v | W03_TOP | SW[7:0] | wire [6:0] HEX0, HEX1 |

MUX는 S=0이면 A, S=1이면 B를 선택합니다. 디코더는 SEL=00/01/10/11에 Y=0001/0010/0100/1000,
X/Z 입력에는 0000을 출력합니다.

## 문법과 오류 관찰

- `always @(*)`: 읽는 입력이 바뀌면 다시 계산합니다. 이번 주에는 클록을 사용하지 않습니다.
- `reg`: always 안에서 대입하는 출력의 선언 형식입니다. 그 자체로 플립플롭을 뜻하지 않습니다.
- 조합회로는 `=`로 대입하고 모든 분기에서 출력을 대입합니다. `begin/end`로 문장을 묶습니다.
- 감도 목록에서 B가 빠지면 B만 바꿨을 때 시뮬레이션 출력이 갱신되지 않습니다.
- S=0 분기에서 대입하지 않으면 이전 값이 유지되고 래치가 생깁니다. 감도 목록 오류와 구분하세요.
- TB의 `#10`은 입력 변경 뒤 계산을 기다리는 용도입니다. RTL에는 쓰지 않습니다.
- `!==`는 X/Z를 포함해 비교하므로 미연결 출력도 검출합니다.

`tb_fix`에서 정상 FIXED는 0→1→0, BAD_SENSITIVITY는 0→0→0,
BAD_ASSIGNMENT는 0→1→1로 관찰됩니다. 최종 PASS는 FIXED만으로 판정합니다.

## 수업 후 검사 과제

A와 B는 각각 0~15, SUM은 자리올림을 보존하는 5비트(0~30)입니다.
BIN5_TO_BCD는 0~31을 십의 자리 TENS와 일의 자리 ONES로 나눕니다.
예를 들어 27은 TENS=2, ONES=7입니다. 이진수→BCD 변환과 BCD→표시 디코딩은 별도 블록입니다.

TOP은 SW[3:0]을 A, SW[7:4]를 B로 사용하고 합계를 HEX1(십의 자리), HEX0(일의 자리)에 표시합니다.
8은 앞자리 0을 포함한 08로 표시합니다. 클록·리셋·카운터는 필요하지 않습니다.
포트는 `.A(신호명)`과 같이 명시적 이름으로 한 줄에 하나씩 연결합니다.
왼쪽은 모듈의 포트 이름이고 괄호 안은 연결할 신호입니다. 내부 신호 선언과 연결은 직접 작성하세요.

7-segment 기준은 active-low, `SEG[6:0]={g,f,e,d,c,b,a}`이며 0이 켜짐입니다.
a는 위, b/c는 오른쪽 위/아래, d는 아래, e/f는 왼쪽 아래/위, g는 가운데입니다.

| BCD | SEG[6:0] |
|---|---|
| 0 | 1000000 |
| 1 | 1111001 |
| 2 | 0100100 |
| 3 | 0110000 |
| 4 | 0011001 |
| 5 | 0010010 |
| 6 | 0000010 |
| 7 | 1111000 |
| 8 | 0000000 |
| 9 | 0010000 |
| 10~15, X/Z | 1111111 (소등) |

## 테스트 입력

| TB | 필수 자극 및 기대 결과 |
|---|---|
| tb_mux2 | A=0, B=1에서 S=0→Y=0, S=1→Y=1. 이후 A=1, B=0으로 바꿔 두 선택값 재확인 |
| tb_lookup | SEL=00,01,10,11에서 IF/CASE 출력 모두 0001,0010,0100,1000. SEL=xx에서 둘 다 0000 |
| tb_fix | A=0,B=0,S=1 시작 → B만 1로 변경 → S만 0으로 변경. FIXED의 Y는 0→1→0. BAD는 관찰용으로 이름을 붙여 출력 |
| tb_add4 | 0+0→0, 3+5→8, 15+1→16, 15+15→30 |
| tb_bin5_to_bcd | 0→00, 9→09, 10→10, 19→19, 20→20, 29→29, 30→30, 31→31 |
| tb_bcd_to_7seg | 0~9 전부를 위 7-segment 표의 패턴으로 검사. 10,15,xxxx에서는 1111111 |
| tb_w03_top | SW=00→00, 53→08, 37→10, 1F→16, FF→30. 여기서 SW는 16진수 표기이며 결과는 십진수 두 자리 |

## 서버에서 실행

교강사가 배포한 `~/DICE/W03` 기준입니다. 다른 위치에 압축을 풀었다면 cd 경로를 바꾸세요.
Bash에서 아래 명령을 한 줄씩 실행하고 편집기를 닫은 뒤 다음 단계로 진행하세요.
answer를 비교 실행할 때는 cd 경로의 todo를 answer로 바꾸면 됩니다.
Icarus 실행에는 라이선스가 필요하지 않습니다.

### 수업 예제 실행 순서



```bash
cd ~/DICE/W03/todo/lesson # TODO 수업 예제 폴더로 이동
pwd # 현재 위치 확인
ls rtl # 제공된 회로 파일 확인
ls tb # 제공된 테스트벤치 확인
mkdir -p build # 컴파일 결과 폴더 준비
mkdir -p logs # 로그 폴더 준비
command -v vcs_queue # VCS 실행 명령 확인
command -v verdi_sub # Verdi 실행 명령 확인
vim rtl/01_mux2.v # MUX를 작성하고 Esc, :wq, Enter로 저장 후 종료
bash 01_run_mux2.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 01_view_mux2.sh # Verdi에서 기존 회로와 파형 확인
vim rtl/02_dec2_if.v # 진리표를 if/else로 작성하고 저장 후 종료
vim rtl/03_dec2_case.v # 동일 진리표를 case로 작성하고 저장 후 종료
bash 02_run_lookup.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 02_view_lookup.sh # Verdi에서 기존 회로와 파형 확인
bash 06_run_fix.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 06_view_fix.sh # Verdi에서 기존 회로와 파형 확인
vim rtl/06_mux_fixed.v # 감도 목록과 출력 대입 누락 수정 후 저장
bash 06_run_fix.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 06_view_fix.sh # Verdi에서 기존 회로와 파형 확인
```

컴파일 오류가 나면 다음 실행 명령으로 넘어가지 않음. 이전 실행 파일이 남아 있을 수 있으므로 코드 수정 후에는 반드시 재컴파일. PASS 예제도 입력을 한 번 바꾸어 재확인.

### 검사 블록 실행 순서

```bash
cd ~/DICE/W03/todo/checkpoint # 검사 과제 폴더로 이동
mkdir -p build # 실행 파일 저장 폴더 준비
mkdir -p logs # 로그 저장 폴더 준비
vim rtl/07_add4.v # 가산기 TODO 작성 후 저장
bash 07_run_add4.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 07_view_add4.sh # Verdi에서 기존 회로와 파형 확인
vim rtl/08_bin5_to_bcd.v # 십진수 자릿수 분리 TODO 작성 후 저장
bash 08_run_bin5_to_bcd.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 08_view_bin5_to_bcd.sh # Verdi에서 기존 회로와 파형 확인
vim rtl/09_bcd_to_7seg.v # 진리표에 따라 case의 출력값 작성 후 저장
bash 09_run_bcd_to_7seg.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 09_view_bcd_to_7seg.sh # Verdi에서 기존 회로와 파형 확인
vim rtl/10_w03_top.v # 블록 사이 신호 선언과 명시적 포트 연결 작성 후 저장
bash 10_run_w03_top.sh # VCS로 컴파일·검사하고 FSDB 저장
bash 10_view_w03_top.sh # Verdi에서 기존 회로와 파형 확인
```

### 필요할 때만 VCS 큐로 재검사

기본 실습은 라이선스가 필요 없는 Icarus로 진행. VCS 확인을 요구할 경우 서버에서 제공하는 `vcs_queue`만 사용. 직접 `vcs`, `vcs_sub` 실행 안내는 넣지 않음.

```bash
cd ~/DICE/W03/todo/checkpoint # 가산기 소스와 TB가 있는 폴더로 이동
mkdir -p build # VCS 실행 파일 폴더 준비
mkdir -p logs # 결과 로그 폴더 준비
command -v vcs_queue # 수업용 VCS wrapper 확인
vcs_queue -full64 rtl/07_add4.v tb/07_tb_add4.v -o build/simv_add4 -R # 큐 안에서 가산기 컴파일과 시뮬레이션 연속 실행
synopsys_queue_status # 대기 상태 확인 시 사용
```

대기 중이면 같은 실행 명령을 반복하지 않음. 큐 상태를 확인하려면 다른 터미널 사용. `mkdir -p`는 폴더가 없으면 만들고 이미 있어도 유지한다는 뜻. `~`는 학생 자신의 홈이며 앞에 역슬래시를 붙이지 않음.

시뮬레이터의 종료코드 0만으로 합격을 판단하지 마세요. 최종 `PASS: 이름`이 있고
`FAIL:`이 없는지 함께 확인합니다. 입력을 바꾸면 기대값도 그 입력에 맞게 수정하세요.
로그 저장이 필요하면 해당 `vvp` 명령 뒤에 `> logs/파일명.log`를 붙이고 로그를 읽습니다.

## 조교 검사표

학생은 정답지를 참고하여 TODO를 모두 완성한 뒤 검사 요청. 실행 버튼만 누른 것으로 끝내지 않고 아래 항목 확인.

| 항목 | 검사 기준 | 짧게 물어볼 내용 |
|---|---|---|
| 수업 예제 | MUX·IF/CASE·수정 코드의 TB PASS | `always @(*)`를 쓰는 이유 |
| 오류 수정 | B만 변경하는 시험과 S=0 시험에서 FIXED 정상 | 감도 목록 누락과 출력 미대입의 차이 |
| 가산기 | 15+1=16, 15+15=30 | SUM이 5비트인 이유 |
| BCD 변환 | 9/10, 19/20, 29/30 경계값 정상 | 이진수 27이 두 자리 2와 7로 바뀌는 과정 |
| 7-segment | 숫자 0~9 및 invalid 소등 정상 | active-low와 default의 의미 |
| 연결 | TOP TODO 전부 완료, 한 줄 한 포트, 통합 TB PASS | 포트 이름과 연결 신호 이름의 차이 |
| FPGA 최종 검사 | 별도 FPGA 절차 제공 후 00·08·10·16·30 실제 표시 | 십의 자리와 일의 자리 연결 확인 |

블록 단위 PASS와 전체 연결 PASS를 구분. 시뮬레이션 PASS만으로 실제 FPGA 검사를 완료했다고 기록하지 않음. 실제 보드 검사는 별도 절차에서 수행합니다.

## 검증 범위

로컬 Icarus 검증 결과는 `99_VALIDATION.md`를 참고하세요.
서버 계정 배포, VCS 큐 실행, 실제 FPGA 동작은 이 패키지의 로컬 검증에 포함하지 않습니다.
Quartus 프로젝트 생성·핀 지정·다운로드 안내는 별도 제공 대상입니다.
