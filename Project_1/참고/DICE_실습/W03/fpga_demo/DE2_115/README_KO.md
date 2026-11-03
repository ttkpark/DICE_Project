# DE2-115: 숫자 한 자리 표시

대상은 **DE2-115 / Cyclone IV E / EP4CE115F29C7**입니다. 보드 모델과 FPGA 전체 부품명을 먼저 확인합니다. 다른 보드이면 이 폴더를 사용하지 않고 상위 [보드 선택 안내](../BOARD_SELECTION_KO.md)에서 다시 선택합니다.

SW3~SW0으로 0~9를 고르면 HEX0에 숫자를 표시하고 10~15에서는 소등하는 완성 예제입니다. RTL 최상위 이름은 `W03_HEX_DEMO`, 프로젝트 이름은 `W03_HEX_DEMO_DE2_115`입니다. 두 보드의 프로젝트·핀·SOF를 섞지 않습니다.

## 1. 보드 설정 확인

이 예제는 JP7 기본 설정(5–6 연결, 2.5V)이 전제입니다. JP7가 기본값인지 먼저 확인하고, 다르거나 불확실하면 조교에게 문의합니다. 전원이 켜졌거나 확장 보드가 연결된 상태에서 임의로 바꾸지 않습니다.

SW와 HEX0 일부 핀의 전압은 JP7에 의존하고 HEX0[0..2]는 고정 2.5V입니다. 따라서 제공 QSF의 11개 입력·출력은 모두 2.5 V입니다. 원래 DE2의 3.3-V LVTTL 설정을 복사하지 않습니다.

| 설정 | 확인할 값 |
|---|---|
| Family | Cyclone IV E |
| Device | EP4CE115F29C7 |
| I/O 표준 | 2.5 V |
| SW[0..3] | AB28, AC28, AC27, AD27 |
| HEX0[0..6] | G18, F22, E17, L26, L25, J22, H22 |

핀은 표의 인덱스 순서입니다. HEX0은 0에서 켜지는 active-low이며, HEX0[0]부터 a·b·c·d·e·f·g 순서입니다. 미사용 핀의 입력 삼상태 예약은 이 수업 예제의 설정입니다.

## 2. 서버에서 코드 확인

아래 명령을 한 줄씩 실행합니다. `verdi`는 기본 도구 이름입니다. 별도 서버 wrapper가 있으면 교강사가 공지한 이름을 사용합니다. 명령이 없으면 라이선스 환경을 임의로 바꾸지 말고 문의합니다.

```bash
cd ~/DICE/W03/fpga_demo/DE2_115 # DE2-115용 예제 폴더로 이동
mkdir -p build logs # 실행 결과와 로그 폴더 준비
command -v vcs_queue # 서버 VCS 큐 wrapper 확인
command -v verdi # Verdi 실행 명령 확인
vcs_queue -full64 -f demo.f -top tb_W03_HEX_DEMO -o build/simv_demo -R -l logs/demo.log # 큐 안에서 컴파일과 TB 실행
ls -lh build/demo.vcd # 새 파형 파일 생성 확인
verdi -f demo.f -top tb_W03_HEX_DEMO -ssf build/demo.vcd # SW와 HEX0 파형 확인
```

`PASS: W03_HEX_DEMO`가 있고 `FAIL:`이 없어야 합니다. `-R`이 실행까지 처리하므로 simv를 따로 실행하지 않습니다. 대기 중 같은 명령을 반복하지 않습니다. VCS 오류가 있으면 Verdi로 넘어가지 않습니다. Verdi 창을 닫은 뒤 다음 단계로 진행합니다. 시뮬레이션 PASS는 핀 설정이나 실제 보드 표시 검증을 대신하지 않습니다.

## 3. Quartus에서 프로그램

1. 이 `DE2_115` 폴더 전체를 짧은 영문 경로에 복사. RTL·TB·파일 목록·QPF·QSF를 함께 유지.
2. `File > Open Project`에서 `W03_HEX_DEMO_DE2_115.qpf` 선택. 같은 이름의 QSF가 없으면 진행하지 않고 문의.
3. `Assignments > Device`에서 위 Family와 Device 확인. 최상위 회로는 `W03_HEX_DEMO`.
4. `Assignments > Settings > Files`에서 `rtl/W03_HEX_DEMO.v`, `rtl/09_bcd_to_7seg.v` 두 RTL만 확인. TB는 합성 파일에 넣지 않음.
5. `Pin Planner`에서 해당 보드의 공식 설명서와 핀·I/O 대조. 미사용 핀은 `As input tri-stated` 확인.
6. `Processing > Start Compilation`. 성공하면 `output_files/W03_HEX_DEMO_DE2_115.sof` 생성.
7. DE2-115 공식 설명서의 JTAG 절차에 따라 전원·USB-Blaster 연결과 보드 모드 확인.
8. `Tools > Programmer`: USB-Blaster와 JTAG 모드 확인. 방금 이 프로젝트에서 생성한 SOF 추가.
9. 대상 장치와 파일 경로를 다시 확인한 뒤 `Program/Configure` 체크, `Start`. 다른 보드나 이전 설정의 SOF 재사용 금지.

부품명·핀·전압 중 하나라도 확실하지 않으면 Start 전에 조교 확인을 받습니다. 해당 FPGA를 지원하는 Quartus 환경이 필요합니다.

배포 전 로컬 Icarus TB PASS와 VCD 생성, Quartus II 13.0.0 Build 156 Web Edition의 전체 컴파일 오류 0개·경고 11개·SOF 생성을 확인했습니다. 결과는 7개 논리 요소·레지스터 0개·핀 11개이며 I/O 규칙 검사 실패는 0개입니다. 11개 핀 설정과 배치 결과도 대조했습니다. SDC·클록 제약 없음, 기본 출력 부하, 기본 출력 구동·슬루 설정 등의 경고가 있어 타이밍 검증 완료를 뜻하지 않습니다. 실제 FPGA 다운로드와 표시 동작은 검증하지 않았습니다.

## 4. 다섯 입력 기록

| SW3 SW2 SW1 SW0 | 입력 | 목표 표시 |
|---|---:|---|
| 0000 | 0 | 0 |
| 0001 | 1 | 1 |
| 1000 | 8 | 8 |
| 1001 | 9 | 9 |
| 1010 | 10 | 전체 소등 |

기초 조사, 보드·FPGA 이름, 프로젝트 이름, 수정한 설정(없으면 없음), Programmer 완료 화면, 숫자 8 보드 사진과 실제 관찰표를 예비보고서 A4 1쪽에 정리합니다. 실행하지 못했다면 미실행으로 기록하고 조교에게 문의합니다.

공식 설명서: 별도 배포 `W03_보드매뉴얼/DE2_115_User_Manual.pdf` 또는 [Terasic DE2-115 공식 PDF](https://www.terasic.com.tw/attachment/archive/502/DE2_115_User_manual.pdf). 다른 보드의 설명서와 혼동하지 않습니다. 전체 발제는 `../../W03_예비보고서_발제와_작성예시.txt` 참고.

장치·핀·I/O는 공식 매뉴얼 v2.3와 Cypress USB System CD v3.0.6의 Golden Top/Default 프로젝트에서 대조했습니다. 다른 보드 리비전이나 변경된 점퍼·확장 보드 구성은 사용 전 공식 자료와 조교에게 확인합니다.
