# 체크포인트: TODO 12곳

기본 작성 파일은 `~/DICE/W04/todo/checkpoint/rtl/alu.v`입니다.
완성 따라 하기 예제는 `../lesson/rtl/alu.v`입니다.

- CP01~03 → CP05~09 → CP04 → CP10~12 순서로 오른쪽 식만 작성하세요.
- 작성한 주석은 `TODO CP01`에서 `DONE CP01`처럼 바꾸세요.
- 포트 선언·v_raw·sum32·SLT case 행·default·관측 신호는 이미 제공했습니다.
- AUTO는 포트 목록과 연결을 정리하며 ALU 식을 대신 작성하지 않습니다.
- `todo`는 처음에도 컴파일되지만 T01에서 FAIL이 정상입니다.
- `blank`는 alu.v가 빈 파일이어서 작성 전 컴파일되지 않습니다.
- 이 체크포인트 TB는 고정 검사입니다. 예상값·비교문·PASS 문장을 수정하지 마세요.
- lesson에서 입력과 기대값을 함께 바꾸는 연습과 구분하세요.

```bash
bash 01_run_alu_check.sh # 작성한 ALU의 34개 사례를 새로 검사
cat logs/alu_check.log # 34개 OK와 마지막 PASS, FAIL 부재 확인
bash 01_view_alu_check.sh # 이번 실행의 파형 확인
```

정확한 마지막 표식은 `PASS: W04_CHECKPOINT (34/34)`입니다.
종료코드 0 또는 오래된 PASS 로그만으로 통과하지 않습니다.
