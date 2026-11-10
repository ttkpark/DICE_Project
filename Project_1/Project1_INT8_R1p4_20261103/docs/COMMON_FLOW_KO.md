# 공통 기능 실행·CPU 합성·전력 측정 - R1.4

## 구조와 작업 위치

패키지 루트에서 실행. `rtl/TOP.v`에는 CORE만 포함. IMEM·DMEM은 `sim/TB_TOP.v`가 TOP 바깥에서 연결하므로 학생이 메모리를 black box로 처리할 필요 없음. 합성 top은 TOP이며 파일 목록은 `synth/rtl.f`.

TOP 입력: CLK, RESET, INSTR[31:0], READDATA[31:0], RESERVED_IN0..19[31:0]. 출력: PC[31:0], MEMWRITE, ALURESULT[31:0], WRITEDATA[31:0], RESERVED_OUT0..19[31:0]. 예약 입력은 모두 0, 예약 출력은 미연결. CORE·CONTROLLER 포트 변경 없음.

현재 공개 starter의 TOP T1/T2와 CONTROLLER는 미완성. 이를 먼저 구현해야 기능·PPA 진행 가능. 제공 Python 기준본의 PASS는 CPU PASS가 아님.

## 1. 주기 설정과 파일 확인

```bash
# synth/common.sdc에서 create_clock의 period 숫자 한 곳만 편집
vim synth/common.sdc
# CPU 소스 목록에 필요한 CPU 내부 모듈만 등록
vim synth/rtl.f
# 포트·합성 경계·SDC·주기 검사
python3 tools/check_release.py
```

입력 INSTR, READDATA와 예약 입력에 min=max 1.00ns, transition 0.10ns. 모든 출력에 min=max 1.00ns, load 20fF, max transition 0.25ns. clock uncertainty setup/hold는 0.10/0.05ns, transition 0.08ns. 숫자 변경은 period 한 곳만 허용.

## 2. VCS 기능 실행과 activity 수집

```bash
# 서버의 VCS queue wrapper로 컴파일하고 공개 16개 case 실행
bash run_sim.sh
# 전체 case의 cycle/load/store 및 주기·소스 해시 확인
cat results/simulation_manifest.json
# demo 실행 로그 확인
cat logs/demo.log
```

개선 프로그램이 `optimized.hex`이면 다음 명령으로 대신 실행.

```bash
# 같은 TB·SDC로 개선 프로그램 실행
python3 tools/run_flow.py sim --program optimized.hex
```

TB가 선언 주기와 같은 clock을 생성. reset 해제 후부터 DONE store까지 cycle·load/store를 셈. VCD는 TOP 인스턴스 `TB_TOP/dut`만 기록. 각 case의 활성 구간을 별도 VCD로 잘라 reset·시작 대기 시간과 park cycle이 power 평균에 섞이지 않도록 함. `ACTIVE_WINDOW`는 시작 falling edge부터 DONE 뒤 첫 falling edge까지이며, 기간은 DONE cycle 수 × 주기와 같음.

명령이 종료 상태 0을 반환해도 FAIL 문자열 또는 PASS 누락이면 공통 도구가 중단. 공개 16개 연습이 전부 성공해야 manifest 생성. 공식 성적은 공개·숨김 공통 24개로 별도 평가.

## 3. SAIF 변환과 CPU-only 합성·STA·power

```bash
# 공통 스크립트가 vcd2saif와 dc_shell_queue를 차례로 호출
bash run_ppa.sh
# 공개 case 측정 요약 확인
cat results/ppa_summary.json
# setup·hold 및 제약 위반 확인
cat reports/setup.rpt
cat reports/hold.rpt
cat reports/constraints.rpt
```

필요 명령: `vcs_queue`, `vcd2saif`, `dc_shell_queue`, Python 3. 서버 공통 library는 SAED32 RVT SS 0.95V 125°C. 설치 경로는 `synth/library_setup.tcl`에 명시. 해당 DB가 없으면 중단하고 조교에게 서버 설정 확인 요청. 학생별 TT·FF 또는 다른 library로 대체 금지. library 파일 자체는 포함하지 않음.

## DC 안에서 진행되는 순서

`synth/run_ppa.tcl`에 실제 명령이 있음. 아래 순서로 읽으면 됨.

1. library 설정, WORK 생성, `saif_map -start`.
2. `synth/rtl.f`의 CPU RTL만 analyze, TOP elaborate, link, check_design.
3. `source synth/common.sdc`, compile. reset은 합성 중 상수화하지 않음.
4. 같은 mapped CPU의 netlist/DDC·cell area 저장.
5. `set_case_analysis 0 [get_ports RESET]`, setup/hold와 제약 보고서 작성. RESET=1 기능은 TB에서 별도 확인.
6. 같은 mapped CPU에 case별 SAIF를 `TB_TOP/dut` 범위로 annotate. case 사이 activity만 초기화하며 재합성하지 않음.
7. case별 `report_saif -hierarchy`, `report_power`. 단위가 있는 report_power의 dynamic+leakage를 읽어 mW로 환산.
8. CPU 평균 power는 Σ(case power × DONE cycles) / Σ(DONE cycles). 모든 case가 같은 선언 주기이므로 실행 시간에 따른 가중 평균임.
9. CPU cell area/power에 기존 계약의 SRAM 면적·동적·정적 추정치를 별도로 가산. 실행시간은 mean(DONE cycles)/f. async delay 추가 없음.

이 flow는 배치·배선 전 합성 추정. 기본 SAIF 이름 매핑과 미주석 항목은 조교가 annotation 보고서로 확인해야 하며, activity 없는 vectorless 결과를 공식 측정값으로 대신 제출하지 않음. PPA summary 생성만으로 공식 PASS나 최종 점수가 확정되지 않음.

## 재현 시 보관할 파일

- 수정한 RTL, synth/rtl.f, synth/common.sdc, 사용 프로그램 .s/.hex/.lst.
- results/simulation_manifest.json, results/ppa_status.json, results/ppa_summary.json.
- results/TOP_mapped.v, TOP_mapped.ddc, TOP_normal_mode.sdc.
- logs/ 전체와 reports/ 전체. 원본·활성 구간 VCD 및 SAIF도 요청 시 제출.
- 실행 도구 버전과 library 경로·corner. source/주기/프로그램 변경 시 반드시 run_sim부터 재실행.

## 이행 및 검증 범위

R1.3a의 u_imem/u_dmem을 TOP에서 빼고, 새 TOP 입력을 연결한 뒤 R1.4 TB로 재실행. 공식 TB의 메모리 scope도 `dut.u_imem/u_dmem`에서 TB의 `u_imem/u_dmem`으로 이행. 학생이 공식 TB를 수정하는 것은 허용하지 않음.

로컬 검증과 서버 실행 여부는 RELEASE_VALIDATION.json에 구분. 상용 도구·library가 없는 PC에서 물리 PPA 수치를 꾸며 제공하지 않음.

참고: Synopsys Power Compiler User Guide의 RTL SAIF name mapping과 read_saif 설명. 배포 서버의 `help read_saif`, `help saif_map`, `help report_power`가 설치 버전의 최종 기준.
