# EE362 Project 1 INT8 starter · Release 1.1

이 패키지는 Project 1의 **Verilog-2001 TOP/CORE/메모리 시작 코드**와 의도적으로 느린 기준 assembly를 함께 담는다. 학생이 완성한 CPU나 공식 채점 결과가 아니다. 공개 전에는 서버에서 컴파일·기능·STA를 확인해야 한다.

## 먼저 구분할 것

- `baseline_int8_fc_slow.s`는 MUL 없이 반복 덧셈으로 곱을 구하고, 중간 곱을 SCRATCH에 저장했다가 다시 읽는 **느린 기준 프로그램**이다. 가장 나쁜 PPA라는 뜻은 아니다.
- `rtl/CORE.v`는 W08의 기본 8개 명령용 datapath 시작 코드다.
- `rtl/CONTROLLER.v`는 학생이 채워야 할 control logic 껍데기다.
- `rtl/TOP.v`는 고정된 외부 interface와 네 개의 내부 연결 TODO를 제공한다. 포트 이름·방향·폭을 바꾸지 않는다.
- `rtl/IMEM.v`, `rtl/DMEM.v`는 **기능 simulation용 memory 모델**이다. 이 파일의 지연을 실제 SRAM timing으로 간주하지 않는다.
- `sim/MEMORY_POWER.v`는 실행 계수와 SAED32 SRAM 매크로 면적으로 메모리 동적전력 및 수업용 정적전력 추정치를 계산하는 **simulation 전용** Verilog 코드다. CPU cell power는 포함하지 않는다. 정적전력 계수는 EDK 실측값이 아닌 고정 채점 정책이다.
- `sim/tb_top_demo.v`는 연습용이다. 학생은 testbench를 수정하지 않는다. 실제 채점은 별도 보관된 고정 testbench로 하며, 로컬 복사본의 변경은 공식 평가에 반영되지 않는다.

## 고정 TOP 포트와 예약 포트

`TOP`은 기존 관찰 포트 `CLK, RESET, PC, INSTR, MEMWRITE, ALURESULT, WRITEDATA`와 32비트 `RESERVED_IN0..19`, `RESERVED_OUT0..19`를 한 줄 한 포트로 선언한다. 모든 이름·방향·폭은 `PROJECT_CONTRACT_KO.md`와 `rtl/TOP.v`를 따른다.

**실제 testbench는 예약 입력 20개를 모두 `32'b0`에 연결하고 예약 출력 20개는 `.RESERVED_OUTn()`으로 열어 둔다.** 여기서 “출력 floating”은 testbench가 그 핀을 **연결하지 않는다**는 뜻이다. `TOP` 출력에 `Z`를 구동하라는 뜻이 아니다. 시작 코드에서는 출력이 미정 상태가 되지 않도록 0으로 구동한다. 필수 기능이 예약 입력의 비영값 또는 예약 출력의 관찰에 의존하면 공식 검사에서 동작할 수 없다.

## 실습 순서

패키지 루트에서 아래 줄을 순서대로 실행한다. 처음에는 TOP의 TODO와 CONTROLLER가 비어 있으므로 마지막 기능 testbench가 PASS하지 않는 것이 정상이다.

```bash
# 기준 assembly를 기계어와 PC 대조표로 변환
python3 tools/rv32i_assembler.py baseline_int8_fc_slow.s -o baseline_int8_fc_slow.hex --listing baseline_int8_fc_slow.lst

# CPU RTL과 별개로 기준 assembly 자체가 정답을 내는지 확인
python3 verify_all.py

# VCS 실행물을 둘 폴더 생성
mkdir -p build

# Verilog-2001 RTL과 연습용 testbench 컴파일
vcs -full64 -top TB_TOP_DEMO rtl/TOP.v rtl/CORE.v rtl/CONTROLLER.v rtl/IMEM.v rtl/DMEM.v sim/MEMORY_POWER.v sim/tb_top_demo.v -o build/simv

# 예시 선언 주파수 100 MHz로 실행. 실제 제출 주파수로 변경
./build/simv +F_MHZ=100
```

먼저 `TOP.v`의 T1~T4 연결을 완성하고 `CONTROLLER.v`의 기본 8개 명령을 구현한다. 소스 `.s`를 바꾼 뒤에는 어셈블러를 다시 실행하여 `.hex`와 `.lst`를 재생성한다. `verify_all.py`는 **제공한 기준 프로그램의 고정 실행량까지 검사**하므로 최적화된 학생 프로그램의 공식 채점기로 사용하지 않는다.

## 메모리 전력 자동 추정

`IMEM.v`는 로드된 `.hex`의 실제 instruction word 수를 센다. `MEMORY_POWER.v`는 DONE store까지의 cycle, 모든 허용 load/store 횟수 및 `+F_MHZ=` 값을 받아 다음을 출력한다.

```text
P_mem_dynamic [mW] = f_MHz / 1000 × (E_IMEM + 12.97 × (LOAD+STORE)/cycles)
P_mem_static_proxy [mW] = 0.020 × (A_IMEM + 50,667.68) / 1,000
P_mem_total [mW] = P_mem_dynamic + P_mem_static_proxy
T [us] = cycles / f_MHz
```

`E_IMEM`은 HEX 길이에 따라 64/256/512-word SRAM 상당 면적에서 자동 선택한다. DMEM은 512-word로 고정한다. 출력은 **동적전력 + 면적비례 정적전력 채점 추정치**이며 CPU cell power와 실제 SRAM timing을 포함하지 않는다. 정적전력은 실제 EDK 누설전력 측정값이 아니다. 전체 전력은 별도 CPU 보고서의 전력에 이 값을 더한다. 실행시간에는 임의의 `async delay`를 덧붙이지 않고, 학생이 선언한 주파수의 setup/hold STA 통과가 별도로 필요하다. 프로젝트 1 PPA 25점은 통과팀 사이 상대평가만으로 결정하며 T:A:P=2:1:1이다. 발표 피어리뷰 10점은 별도 평가다. 세부 기준은 `PROJECT_CONTRACT_KO.md` 참조.

## 현재 검토본의 한계

기본 assembly/어셈블러는 필수 8개 명령만 지원한다. 명세의 선택 RV32I 확장용 공식 어셈블러·기능 검사, 합성용 memory macro timing, 숨김 case 채점 덱은 이 폴더에 포함되지 않았다. 이 릴리즈는 포트·메모리·평가 계약을 고정한 **배포 검토본**이다. 학생 공개 전에 조교가 서버의 도구와 공식 채점 계약을 검증한다.
