# EE362 Project 1 INT8 선형계층 - Release 1.3a (2026-10-23)

이 ZIP은 발표자료(PPTX·PDF), 기본 실습 파일, 기준 프로그램, 공통 CPU 제약(SDC)과 적용 안내를 함께 담은 학생 배포본입니다. 00·01분반은 같은 파일을 사용합니다.

## R1.3a 변경 사항

- 공통 SDC를 처음 보는 학생도 읽을 수 있도록 변수·조건문·계산식 없이 명령별 고정 숫자로 정리. 팀별로 바꿀 곳은 `create_clock`의 `-period 4.00` 숫자 한 곳뿐입니다. `4.00 ns`는 250 MHz 예시이며 목표 주기에 맞게 변경합니다.
- 합성 전에는 SDC를 `source`하고, 합성·link 후 정상 모드 STA에서 `set_case_analysis 0 [get_ports RESET]`을 별도로 실행합니다. 적용 순서를 안내문에 명시했습니다.
- 기능, 고정 포트·ISA 계약, 채점 기준, PPTX·PDF의 내용은 R1.3과 같습니다.

## R1.3 변경 사항

- 데이터 입력과 출력의 `set_input_delay`·`set_output_delay`는 `-min`과 `-max`를 각각 모두 **1.00 ns**로 고정. 이 값은 팀별 선언 주파수에 따라 재계산하지 않음.
- `RESET`은 **동기 active-high**. `RESET=1`이 clock 상승 에지에서 reset을 적용하며, active-low 또는 비동기 reset으로 변경할 수 없음.
- 정상 동작 모드 STA에서는 합성·link가 끝난 뒤 `set_case_analysis 0 [get_ports RESET]`을 적용. 합성 중 적용하면 reset 회로가 제거될 수 있으므로 금지. reset assertion/deassertion은 공식 기능 시뮬레이션에서 별도 확인.
- setup/hold uncertainty, transition, load 등 나머지 공통 SDC 값은 PPT 12페이지와 `Project1_INT8_SDC_적용안내_20261023.md`에 요약.
- R1.2의 PPA 25점 + 발표 피어리뷰 10점, 기능/재현/timing PASS/FAIL 관문, 고정 포트·ISA 계약은 유지.

## 주요 파일

1. `Project1_INT8_PPA_피어리뷰_Release1p3_KO_20261023.pptx` / `.pdf`: 프로젝트 명세와 공통 제약.
2. `Project1_INT8_CPU_ONLY_20261023.sdc`: CPU-only clock·I/O·전기 조건. Clock period 숫자 한 곳만 팀별 설정.
3. `Project1_INT8_SDC_적용안내_20261023.md`: 합성 단계와 합성 후 STA 단계의 사용 구분.
4. `Project1_INT8_Starter_20261020/`: Verilog TOP/CORE/CONTROLLER 껍데기, 기능 예제, 문서.
5. `Project1_INT8_Baseline_20261007.zip`: 느린 기준 프로그램과 기존 기본 실습. 내부의 오래된 채점/PPA 설명보다 **R1.3 명세를 우선** 적용.

기능 예제의 PASS 출력은 학생 구현 CPU의 통과나 PPA 결과를 증명하지 않습니다. 공식 평가에서는 고정 테스트벤치와 공통 24개 case, 선언 주파수에서의 setup·hold를 다시 확인합니다.
