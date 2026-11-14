# R1.7 서버 측정 (2026-11-14, DICE)

이 작업 폴더를 그대로 서버에서 돌린 결과다. RTL은 `rtl/` EX 분기판, 공개 16 case. 아래 첫 표는 기존 1.62 ns 실행이다.
`int8_opt64v2` 를 먼저, `int8_fastv2` 를 마지막에 돌렸다. 그래서 서버 작업 폴더에 남은 결과(= 제출용 DDC)는 `int8_fastv2` 실행분이다.

```bash
python3.12 tools/check_release.py
bash run_sim.sh --program programs/int8_opt64v2.hex && bash run_ppa.sh
bash run_sim.sh --program programs/int8_fastv2.hex  && bash run_ppa.sh
```

| | `int8_fastv2` (기존 제출 초안) | `int8_opt64v2` |
|---|---:|---:|
| 기능 | 16/16 PASS | 16/16 PASS |
| timing | PASS, setup +0.00261915 / hold +0.114771 ns | 같음 |
| 평균 cycle | 630.25 | 777.125 |
| T | 1.021005 µs | 1.2589425 µs |
| A (CPU 22322.99 + IMEM + DMEM 50667.68) | 100342.97 µm² (IMEM 256) | 81704.17 µm² (IMEM 64) |
| P (CPU + 메모리 동적 + 정적) | 8.8303 + 5.0197 + 1.5604 = 15.4104 mW | 8.7067 + 1.9638 + 1.1876 = 11.8581 mW |
| DDC / 계층 | 416 KB, TOP > CORE > CONTROLLER | 같음 |
| fingerprint | `e486b618bea44bc65e97b57f4e8668ad8fd524941ae36f8605b912e3b3ea2260` | `61c24186f098823f99d22592562c66423b2269baa94f9f3d800782f2073a1d9b` |

- 값은 앞선 측정과 끝자리까지 같다: `int8_fastv2` 는 R1.6 Tcl 실행(11-12), `int8_opt64v2` 는 R1.4 Tcl 비교 실험(11-11). R1.7 Tcl 은 R1.6 과 같고 RTL·주기도 같기 때문이다.
- `logs/dc_ppa.log` 안의 `error "P1: ..."` 줄은 Tcl 스크립트 본문이 그대로 찍힌 것이고 실제 오류가 아니다. 두 실행 모두 `P1_PPA_COMPLETE` 로 끝났다.
- 폴더마다 `results/`(ppa_summary·status·manifest, TOP_mapped.ddc/.v, TOP_normal_mode.sdc), `reports/`(setup, hold, cpu_area, cpu_hierarchy, case별 power·annotation), `logs/`(compile, case 16개, vcd2saif, dc_ppa).
- 기존 제출 초안은 `int8_fastv2` 결과로 만든 `../../submission/Project1_TEAM_ID.zip`.

## 4입력 Horner 프로그램 (1.52 ns)

같은 EX 분기 RTL에서 `int8_horner4`를 측정했다. 입력 네 개의 비트별 가중치를 출력별 부분합에 모으고, 가중치 각각을 두 배로 만드는 대신 부분합을 두 배로 만든다. 기본 8개 명령만 사용한다. 253 words로 `int8_fastv2`와 같은 256-word IMEM 구간이다.

| 항목 | `int8_horner4` |
|---|---:|
| 주기 / 주파수 | 1.52 ns / 657.89 MHz |
| 공개 기능 | 16/16 PASS |
| Setup / hold slack | +0.000328541 / +0.102992 ns |
| 평균 DONE cycle | 491.25 |
| LOAD / STORE | 케이스당 52 / 5 |
| 실행시간 | 0.746700 µs |
| 총면적 | 100,344.24 µm² |
| 총평균전력 | 16.2857 mW |

위 `fastv2` 1.62 ns 대비 사이클은 22.1%, 실행시간은 26.9% 줄었다. 총면적은 약 1.27 µm², 총평균전력은 0.8753 mW 늘었다. 실행시간 비교에는 프로그램과 주기의 효과가 모두 포함된다. 수치는 공개 16개 기준이며 공식 24개 평가는 별도로 진행된다.

- 소스는 [어셈블리](../../programs/int8_horner4.s), [HEX](../../programs/int8_horner4.hex), [LST](../../programs/int8_horner4.lst)에서 확인한다.
- [1.52 ns SDC](int8_horner4/synth/common.sdc), [PPA 요약](int8_horner4/results/ppa_summary.json), [시뮬레이션 기록](int8_horner4/results/simulation_manifest.json), [전체 계층 DDC](int8_horner4/results/TOP_mapped.ddc), [계층 보고서](int8_horner4/reports/cpu_hierarchy.rpt)를 같은 실행에서 보관했다. 기능 로그와 STA·면적·케이스별 전력·SAIF 보고서도 이 실행 폴더에 있다.
- GitHub의 프로젝트 기본 SDC는 위 1.62 ns 실험의 조건이다. 1.52 ns 결과를 재현하려면 DICE에서 프로젝트 사본의 루트로 이동해 아래를 실행한다.

```bash
cp measurements/R1p7_20261114/int8_horner4/synth/common.sdc synth/common.sdc
bash run_sim.sh --program programs/int8_horner4.hex && bash run_ppa.sh
```
