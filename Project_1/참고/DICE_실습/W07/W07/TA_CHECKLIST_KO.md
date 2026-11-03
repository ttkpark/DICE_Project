# W07 조교 체크리스트

수업 전에 동일 서버에서 정답 VCS/Verdi와 DC 30개 명령을 실행합니다. `synth/scripts/library_setup.tcl`의 DB 접근 권한과 report_units의 ns/fF를 확인합니다. 라이선스 대기를 고려하고 실제 생성한 보고서만 예비 자료로 보관합니다.

30분 도입: 0–2분 맥락, 2–12분 RTL 읽기, 12–16분 정답 실행/파형, 16–20분 launch/capture와 setup/hold, 20–27분 DC 비교, 27–30분 체크포인트 시작. 대면 검사는 이후 실습 시간에 순차 진행합니다.

## 검사 기준

|검사항목|통과 기준|
|---|---|
|RTL 제어값|T0–T9의 대입 38곳 전체 확인, 정답 또는 동등 동작, latch 없는 조합논리|
|고정 TB|변경 없는 제공 TB로 새 CONTROL PASS (16/16)|
|안전 기본값|C11·C15에서 PCSRC/MEMWRITE가 이전 명령 값을 유지하지 않음|
|지원 범위|C12·C13·C16의 미지원 기능을 ILLEGAL=1로 처리|
|DC 준비|link/check_design 오류 해결, mapped=true, 단위 확인|
|타이밍 기록|실제 4개 보고서의 경로·arrival·required·slack 기록|
|해석|setup과 hold의 slack 방향 및 주기 변화 차이 설명|

교수자 답안: T1=001, T2=010, T3=01, T4=1, T5=10, T6=jump | (branch & ZERO). SW: RW=0/MW=1. BEQ PCSRC=0/1. JAL target=PC+imm, return=PC+4. 재합성하지 않는 이유: 논리 최적화·셀 선택 변화 없이 시간 예산 변화만 비교. **STA 절대 수치 정답은 고정하지 않음.**

본인이 어떤 신호를 고쳤는지 설명하면 answer 참고 허용. 단계별 검사 결과가 없다면 다른 학생 보고서 복사로 통과시키지 않음. 배점은 교강사 결정 사항이며 여기서 임의 확정하지 않음.


## 확인할 실제 증거

- 새 logs/sim.log의 C01–C16과 CONTROL PASS (16/16), 새 FSDB의 신호.
- RTL은 0으로 제공된 TODO 대입 38곳을 모두 확인·완성. 0을 유지한 항목도 이유를 설명. TB 변경 없이 실행.
- T1은 SUB case의 ALUCTRL. BEQ의 ALUCTRL=001을 잘못 바꾸지 않았는지 확인.
- JAL에는 funct3 조건을 붙이지 않음. invalid 이후 write/branch/jump 모두 꺼짐.
- DC check_design=1, is_mapped=true, check_timing의 경고 검토.
- CLK 하나, 10ns→5ns 사이 compile 없음, max/min 보고서 네 개에 register 경로 존재.
- slack 수치를 고정하지 않음. 동일 경로 setup slack은 5ns 감소, same-edge hold는 주기 변경으로 개선되지 않음.

[학생 실행 안내](README_KO.md) · [정답과 오류 해결](instructor/ANSWER_KO.md) · [제작 검증 기록](instructor/VALIDATION.md)
