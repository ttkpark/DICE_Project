# Project 1 · R1.5 어셈블리 도구 업데이트 (2026-11-12)

R1.5 어셈블리 도구는 R1.7 누적 업데이트에 포함되어 있습니다. R1.4 배포본의 프로젝트 폴더 안에서 R1.7 ZIP을 풀어 적용합니다. 팀이 작성한 RTL, 어셈블리, HEX는 그대로 둔 상태에서 업데이트할 수 있습니다.

```bash
# 프로젝트 폴더로 이동합니다. 폴더 이름을 바꾼 경우 실제 이름을 사용합니다.
cd Project1_INT8_R1p4_20261103
# 업데이트 ZIP을 상위 폴더에 내려받았을 때의 예시입니다.
unzip -o ../Project1_R1p7_Update_20261112.zip
# 업데이트된 어셈블러의 37개 허용 목록을 확인합니다.
python3.12 tools/rv32i_assembler.py --list-instructions
# 팀의 optimized.s를 제출용 HEX와 listing으로 변환합니다.
python3.12 tools/rv32i_assembler.py optimized.s -o optimized.hex --listing optimized.lst
# 공개 demo 케이스를 Python 기능 모델로 확인합니다.
python3.12 tools/reference_run.py --program optimized.hex --case cases/demo.json
# 팀 CPU RTL로 공개 케이스를 실행합니다.
bash run_sim.sh --program optimized.hex
```

## 사용 가능한 명령어

| 구분 | 명령어 |
|---|---|
| 필수 8개 | ADD SUB AND ADDI LW SW BEQ JAL |
| 선택 29개 · register 연산 | SLL SLT SLTU XOR SRL SRA OR |
| 선택 · immediate 연산 | SLLI SLTI SLTIU XORI SRLI SRAI ORI ANDI |
| 선택 · load/store | LB LH LBU LHU SB SH |
| 선택 · branch | BNE BLT BGE BLTU BGEU |
| 선택 · upper immediate 및 jump | LUI AUIPC JALR |

위 37개는 Harris & Harris RISC-V판 부록 B 표 B.1의 전체 명령입니다. 그 외 명령과 인코딩은 제출에서 금지합니다. 대표적으로 MUL과 M 확장 전체, RV64I, C, F/D, FENCE, FENCE.I, ECALL, EBREAK, CSR 및 권한 명령, 사용자 정의 opcode, `li`, `mv`, `nop`, `j`, `ret` 같은 의사 명령이 해당합니다.

## 어셈블리 작성 형식

| 유형 | 예시 | 피연산자 기준 |
|---|---|---|
| register | `sra x5, x6, x7` | 레지스터 표기는 x0~x31 |
| immediate | `addi x5, x6, -1` | signed 12-bit, −2048~2047. 음수는 `-1`처럼 부호를 붙여 작성 |
| shift immediate | `srai x5, x6, 31` | 0~31 |
| load/store | `lbu x5, 1(x6)`, `sh x5, 2(x6)` | signed 12-bit byte offset. 실제 주소는 접근 폭에 맞게 정렬 |
| branch / JAL | `bne x5, x6, loop`, `jal x1, target` | 라벨 또는 현재 PC 기준 byte offset. 목적지는 4바이트 정렬. 숫자 범위는 branch −4096~4092, JAL −1048576~1048572 |
| upper immediate | `lui x5, 0x12345` | 명령에 들어갈 상위 20비트 필드. 예시 실행 결과는 x5 = 0x12345000. unsigned 20-bit 또는 signed 20-bit 표기 가능 |
| JALR | `jalr x0, x1, 0` 또는 `jalr x0, 0(x1)` | signed 12-bit byte offset. 목표 주소는 `(rs1 + imm) & ~1`이며 4바이트 정렬 필요 |

한 줄에 명령 하나를 작성합니다. `label:`, `#` 또는 `//` 주석, 10진수와 `0x`/ `0b` 정수 표기를 사용할 수 있습니다. 제출용 프로젝트 코드는 PC 0에서 시작하므로 `--base` 기본값을 사용합니다. GNU 어셈블러 지시어(`.text`, `.word` 등)와 재배치 식은 사용하지 않습니다.

## 선택 명령 사용 및 검증

- 팀 CPU에 사용한 선택 명령을 표준 동작대로 구현합니다. 예를 들어 BNE는 두 레지스터가 다를 때 현재 PC에 branch offset을 더하고, 같을 때 PC+4로 진행합니다. 어셈블 성공과 Python 기능 모델 PASS 이후에 팀 RTL의 기능을 별도로 확인합니다.
- 제출 시 사용한 선택 명령 목록, 명령별 단독 기능 시험과 실행 결과, 팀 프로그램의 `.s`, `.hex`, `.lst`를 제출합니다. 예를 들어 BNE는 taken과 not taken을 각각 검사합니다. 기본 8개는 모든 팀의 공통 검사 대상입니다.
- 고정 DMEM은 32비트 word 인터페이스입니다. CPU에서 유효 주소의 하위 비트로 byte/halfword lane을 선택하고 버스에는 하위 2비트를 0으로 만든 주소를 냅니다. 좁은 store는 READDATA의 기존 word에서 해당 lane만 바꾼 32비트를 WRITEDATA로 보냅니다.
- 허용 목록과 최신 제출 항목은 `PROJECT_CONTRACT_KO.md`를 참조합니다. R1.7 실행 방법과 전체 계층 DDC 제출 절차는 `RELEASE_NOTES_KO.md`에 정리되어 있습니다.

## 발표자료 제출

팀별 제출물에 **12주차 발표 슬라이드 1부(PPTX 또는 PDF)**를 넣습니다. 기존 R1.4 안내 PDF 24쪽의 `report/project1.pptx`는 발표 슬라이드를 뜻하며, 예시 경로는 `presentation/project1.pptx`로 정정합니다. 별도 서술형 보고서는 제출하지 않습니다. 기능·STA·CPU 면적 및 전력 도구 출력과 재현 자료는 제출물에 포함합니다.
