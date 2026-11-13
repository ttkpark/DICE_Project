# R1.7 서버 측정 (2026-11-14, DICE)

이 작업 폴더를 그대로 서버에서 돌린 결과다. RTL은 `rtl/` EX 분기판, 주기 1.62 ns, 공개 16 case.
`int8_opt64v2` 를 먼저, `int8_fastv2` 를 마지막에 돌렸다. 그래서 서버 작업 폴더에 남은 결과(= 제출용 DDC)는 `int8_fastv2` 실행분이다.

```bash
python3.12 tools/check_release.py
bash run_sim.sh --program programs/int8_opt64v2.hex && bash run_ppa.sh
bash run_sim.sh --program programs/int8_fastv2.hex  && bash run_ppa.sh
```

| | `int8_fastv2` (최종) | `int8_opt64v2` |
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
- 제출본은 `int8_fastv2` 결과로 만든 `../../submission/Project1_TEAM_ID.zip`.
