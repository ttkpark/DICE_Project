# W05 실험 — 순차논리와 프로그램 카운터

**조합회로가 다음 값을 계산하고, 레지스터는 클럭 상승 에지에서 그 값을 저장합니다.**

기본 실습 경로는 `todo`입니다. **예제 3개와 체크포인트 모두 내부 동작을 직접 채워야 합니다.**
수정 전 RTL은 문법상 컴파일되지만 기능 검사에서 FAIL이 나오는 것이 정상입니다.
TODO의 임시값은 정답이 아닙니다. 정답 RTL은 `answer`에 별도로 제공합니다.
정답 참고는 허용하지만, 새 실행 결과와 동작 설명으로 이해 여부를 확인합니다.

## 1. 폴더와 수업 흐름

```text
W05/
  README.md                       학생용 안내서
  todo/
    lesson/                       내부 동작을 채우는 예제 3개
      rtl/                        DFF, 두 단계 레지스터 2종, PC의 TODO
      tb/                         순서대로 읽는 검사기
      *.f                         해당 폴더의 소스 목록
      *.sh                        컴파일·실행 및 파형 보기
    checkpoint/                   PC TODO 6개와 고정 11단계 검사
  answer/                         완성 RTL과 동일한 검사기·실행 파일
  blank/                          모듈·포트만 주는 자유 작성용
  instructor/                     정답 해설, 조교 검사표, 예비보고서, 검증 결과
```

`todo`, `answer`, `blank`의 TB·filelist·실행 스크립트는 같습니다. RTL의 완성도만 다릅니다.
기본 수업에서는 `todo`에 머물며 실습합니다. `blank`는 추가로 자유 작성하고 싶은 학생용입니다.

| 시간 | 할 일 | 관찰 목표 |
|---|---|---|
| 0–3분 | 폴더와 입력·출력 확인 | 조합회로와 저장 회로 구분 |
| 3–10분 | DFF TODO 2개 작성·실행 | 에지 사이 유지, 상승 에지 저장, 비동기 reset |
| 10–16분 | 두 단계 레지스터의 우변 작성·비교 | 이전 q1과 이미 바뀐 q1의 차이 |
| 16–25분 | PC TODO 작성·실행 | 0 → 4 → 8 → 24 → 28 |
| 25–30분 | 체크포인트 TODO 위치 확인·작성 시작 | 계산 부분과 저장 부분 설명 |

앞부분은 교강사의 설명과 함께 따라 합니다. 학생별 작성 속도에 따라 예제 마무리와 체크포인트 검사는 이후 실습 시간에 진행합니다.

## 2. 압축 풀기

다운로드 파일이 `~/Downloads/W05.tar.gz`에 있다고 가정합니다. 업로드 위치가 다르면 압축 파일 경로만 바꾸세요.

```bash
mkdir -p ~/DICE                         # 실습 상위 폴더를 생성하거나 기존 폴더를 유지합니다.
cd ~/DICE                              # 실습 상위 폴더로 이동합니다.
ls                                     # 기존 W05 폴더가 있는지 확인합니다.
```

**W05 폴더가 이미 있으면 여기서 멈추고 조교에게 문의하세요. 기존 답안을 덮어쓰지 않습니다.**
없을 때만 이어서 실행합니다.

```bash
tar -xzf ~/Downloads/W05.tar.gz         # W05 폴더를 풉니다.
cd W05/todo/lesson                      # 학생용 예제 작성 폴더로 이동합니다.
ls                                     # 실행 파일과 rtl·tb 폴더를 확인합니다.
```

`mkdir -p`는 부모 폴더까지 만들고 이미 있는 폴더는 유지합니다. `~`는 현재 로그인한 사용자의 홈 폴더입니다.
편집은 vim으로 안내합니다. 파일을 연 뒤 `i` → 작성 → `Esc` → `:wq` → `Enter`로 저장·종료합니다.

## 3. 예제 1 — DFF

`rtl/dff.v`에서 D1은 reset 초기값, D2는 상승 에지에 저장할 입력입니다. 포트와 이벤트 제어, `<=`는 제공되어 있습니다.

```bash
vim rtl/dff.v                           # TODO D1·D2의 잘못된 임시값을 완성합니다.
bash 01_run_dff.sh                      # 새로 컴파일·실행하여 W05 DFF PASS를 확인합니다.
bash 01_view_dff.sh                     # 파형에서 clk·reset·data·q를 추가하고 관찰합니다.
```

첫 reset은 2ns에 올라가며 첫 상승 에지 5ns 전에 q=0이 됩니다.
reset 해제 뒤 10ns에 data=1로 바뀌어도 q는 유지되고 15ns 상승 에지에 1을 저장합니다.
20ns에 data=0으로 바꾸면 25ns까지 q=1이 유지됩니다. 37ns의 reset 재인가도 관찰하세요.
파형 창을 닫은 뒤 다음 예제로 진행합니다.

클럭 주기를 바꿔도 “상승 에지에서 저장하고 에지 사이에는 유지한다”는 규칙은 같습니다.
TB의 `#1`은 nonblocking 갱신이 끝난 결과를 읽기 위한 관찰 지연이며 실제 플립플롭의 지연 모델이 아닙니다.
latch는 활성 레벨 동안 입력을 통과시키는 저장소, setup/hold는 에지 주변의 입력 안정 시간입니다. 상세 내용은 후속 강의에서 다룹니다.

## 4. 예제 2 — 두 단계 레지스터

`pipeline_good.v`와 `pipeline_bad.v`의 TODO 네 곳씩을 채웁니다.
각각 두 초기값, 첫 단계가 받을 입력, 두 번째 단계가 받을 첫 단계 신호를 작성합니다.
제공된 연산자는 유지합니다. good은 `<=`, bad는 비교를 위해 같은 always 블록 안에서 `=`를 사용합니다.

```bash
vim rtl/pipeline_good.v                 # TODO G1~G4의 우변을 작성합니다.
vim rtl/pipeline_bad.v                  # TODO B1~B4의 우변을 작성합니다.
bash 02_run_pipeline.sh                 # 두 모듈을 같은 입력으로 실행합니다.
bash 02_view_pipeline.sh                # good_q1·good_q2·bad_q1·bad_q2를 비교합니다.
```

| data=1 유지 | good의 (q1,q2) | bad의 (q1,q2) |
|---|---|---|
| 첫 상승 에지 뒤 | (1,0) | (1,1) |
| 두 번째 상승 에지 뒤 | (1,1) | (1,1) |

`<=`는 갱신 전 값을 읽으므로 레지스터 사이의 이전 상태 전달을 표현합니다.
같은 블록의 `=`는 앞선 대입 결과를 다음 문장이 바로 읽습니다.
`=`만 보고 조합회로라고 판단할 수는 없습니다. 이벤트 제어와 데이터 의존성도 함께 봐야 합니다.
bad 모듈은 비교 관찰용이며 두 단계 레지스터의 작성 권장 방식은 good입니다.

## 5. 예제 3 — PC

PC는 다음에 가져올 명령어 주소를 보관합니다. 이번에는 고정 길이 32비트 명령어를 가정하므로 순차 주소는 4바이트 증가합니다.
TB가 `PCSrc`와 `ImmExt`를 직접 줍니다. 명령어 디코더와 분기 조건 판정은 만들지 않습니다.
`ImmExt`는 부호 확장·재배열·정렬 처리가 끝난 바이트 오프셋입니다.

`rtl/PC.v`의 TODO 6곳을 작성합니다. 두 주소 후보 계산, 후보 선택, reset 초기화, 정상 저장, 출력 연결 순서입니다.

```bash
vim rtl/PC.v                            # PC 예제의 TODO 1~6을 작성합니다.
bash 03_run_pc.sh                       # PC 주소 시퀀스와 에지 사이 유지를 검사합니다.
bash 03_view_pc.sh                      # clk·reset·pc_src·imm_ext·pc와 u_pc 내부 신호를 봅니다.
```

| 시점 | 동작 | 저장된 PC |
|---|---|---:|
| reset | 비동기 초기화 | 0 |
| 15ns 상승 에지 | 순차 갱신 | 4 |
| 25ns 상승 에지 | 순차 갱신 | 8 |
| 30ns 입력 변경 | 분기 선택, offset=16 | 8 유지 |
| 35ns 상승 에지 | 현재 주소에서 분기 | 24 |
| 45ns 상승 에지 | 순차 갱신 | 28 |

파형에서 `u_pc.PCPlus4`, `u_pc.PCTarget`, `u_pc.PCNext`, `pc`를 함께 보세요.
PCNext는 다음 주소 후보라 에지 전에 바뀔 수 있고, PC는 에지에서 저장됩니다.
분기 기준은 현재 PC이므로 8에서 offset=16이면 24입니다.
주소 계산은 32비트 덧셈이며, 모든 RISC-V 구성에서 항상 +4인 것은 아닙니다.

입력 변경 실습: `tb/tb_03_pc.v`의 EDIT A에서 offset을 8로 바꾸고,
EDIT B의 검사 상수·오류 메시지는 16, EDIT C는 20으로 수정하세요.
예상 순서는 `0 → 4 → 8 → 16 → 20`입니다. 이 실습에서는 예제 TB만 수정합니다.

```bash
vim tb/tb_03_pc.v                       # EDIT A·B·C의 입력과 기대값을 함께 바꿉니다.
bash 03_run_pc.sh                       # offset=8의 새 시퀀스를 검사합니다.
bash 03_view_pc.sh                      # 바뀐 분기 주소와 다음 순차 주소를 확인합니다.
```

## 6. 체크포인트

예제 PC를 참고하여 `todo/checkpoint/rtl/PC.v`의 TODO 6곳을 완성하세요.
체크포인트 TB와 filelist는 수정하지 않습니다. 정답을 참고해도 새 실행과 구두 설명이 필요합니다.

```bash
cd ../checkpoint                       # 학생용 체크포인트 폴더로 이동합니다.
vim rtl/PC.v                            # TODO 1~6을 완성합니다.
bash run.sh                            # 고정 11개 검사와 W05 CHECKPOINT PASS를 확인합니다.
bash view.sh                           # 최신 PC 파형과 동작 중 reset을 확인합니다.
```

검사 순서는 reset → reset 유지 → 4 → 8 → 24 → 28 → -4 분기로 24 → offset 0으로 24 유지 →
입력만 바꿔도 24 유지 → 에지 사이 reset으로 0 → 재시작 4입니다.

조교 앞에서 새로 실행한 `W05 CHECKPOINT PASS (11/11)`과 파형을 제시하세요.
“PCNext와 PC는 언제 달라지는가?”, “PC=8에서 offset=16이면 왜 24인가?”를 설명합니다.
`<=` 사용은 소스에서 별도로 확인합니다. 단일 레지스터에 `=`를 써도 기능 검사만으로 항상 구분되지는 않습니다.

## 7. 실행 문제가 생기면

수정 전 TODO의 FAIL은 정상입니다. `logs`의 첫 FAIL 번호와 TB의 해당 기대값을 보고 RTL을 완성하세요.
컴파일 오류는 포트·철자·세미콜론을 확인하고, TIMEOUT은 클럭과 이벤트 대기를 확인합니다.
wrapper가 없거나 라이선스·DISPLAY 오류가 있으면 조교에게 서버 환경을 확인하세요.

실행 스크립트는 자신의 폴더로 이동하고 이전 파형·PASS 표시를 지운 뒤 컴파일합니다.
`-R`이 시뮬레이션까지 실행하므로 simv를 따로 재실행하지 않습니다.
파형 보기 스크립트는 이번 PASS와 새 FSDB가 있을 때 열며, 실행 뒤 소스가 바뀌었으면 재실행을 요청합니다.
`build`와 `logs`는 실행할 때 생깁니다.

wrapper 직접 실행이 필요한 경우 아래 명령은 checkpoint 폴더 기준입니다. 평소에는 `run.sh`와 `view.sh`를 사용하세요.

```bash
mkdir -p build                         # 실행 파일과 파형 폴더를 만듭니다.
mkdir -p logs                          # 로그 폴더를 만듭니다.
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f checkpoint.f -top tb_checkpoint -Mdir=build/csrc -o build/simv -l logs/checkpoint.log -R # 큐에서 컴파일·실행하고 FSDB를 저장합니다.
ls -l logs/checkpoint.log build/checkpoint.fsdb # 로그와 파형이 이번 실행 시각으로 갱신되었는지 확인합니다.
verdi_sub --fsdb build/checkpoint.fsdb --filelist checkpoint.f --top tb_checkpoint # 이번 실행이 PASS한 뒤 파형을 엽니다.
```

## 8. 선택 안내와 예비보고서

Emacs를 선호하면 vim 명령 대신 아래 명령 하나를 사용합니다.
배포 코드는 AUTOARG/AUTOINST가 이미 확장되어 있어 AUTO를 실행하지 않아도 컴파일됩니다.

```bash
emacs rtl/PC.v                         # Emacs를 선택한 경우 편집합니다. 필요하면 M-x verilog-auto를 실행합니다.
```

완성 코드 참고 경로는 [answer/lesson/rtl](answer/lesson/rtl), [answer/checkpoint/rtl/PC.v](answer/checkpoint/rtl/PC.v)입니다.

예비보고서: 다음 세 항목을 조사하여 A4 1쪽 이내로 정리하세요.

- 조합회로와 순차회로의 차이 및 플립플롭의 역할.
- 클럭 상승 에지와 reset의 의미, 순차 always 문에서 nonblocking 대입을 사용하는 이유.
- PC가 현재 명령어 주소를 저장하는 이유, PC+4와 분기 주소의 차이.

간단한 그림·짧은 코드 첨부가 가능하며 참고자료 출처를 표기합니다. 실행 결과·FPGA 사진 제출은 요구하지 않습니다.
FPGA 관찰은 별도 선택 확장입니다. 이번 패키지의 기본 통과 조건은 시뮬레이션과 설명입니다.
