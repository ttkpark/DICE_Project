# 기준 프로그램과 개선 프로그램의 PPA 비교

## 기준본의 성격

이 패키지는 signed INT8 선형계층을 실행하는 느린 **프로그램** 기준본. 반복 덧셈의 실행량과 SCRATCH 접근은 실제 코드에서 발생. 가장 큰 회로, 가장 큰 전력, 가장 느린 최대 동작 주파수를 갖는 **하드웨어**라는 주장은 하지 않음.

작은 ALU로 반복 덧셈을 실행하면 시간이 길어지는 대신 곱셈기 면적을 줄일 수도 있음. MUL을 추가하면 명령 수가 줄어도 조합 경로가 길어지거나 면적·전력이 증가할 수 있음. 성능·전력·면적 세 값을 따로 비교할 것.

## 기능 통과 조건

- 같은 X·W·BIAS와 같은 주소 역할·DONE_TOKEN으로 실행
- 모든 Y 4-word가 INT32 정답과 일치
- 모든 출력 store 후 DONE_TOKEN 기록
- 입력·configuration 영역 훼손 없음
- timeout 없음

## 측정 조건

1. 같은 실제 CPU/TOP 인터페이스와 같은 메모리 계약 사용
2. 같은 합성 library·corner·입출력 제약 사용
3. clock period를 바꾸면 setup뿐 아니라 hold도 확인
4. reset 해제 후 valid DONE store까지 실제 CPU clock edge 수 측정
5. 시간은 실제 cycle 수 × 인정된 clock period로 계산
6. area는 같은 합성 영역끼리 비교. 메모리 포함 여부와 중복 계상 여부 명시
7. power는 같은 workload와 같은 activity 측정 방식으로 비교
8. 에너지는 평균 전력 × 실행시간으로 별도 계산. 전력 감소와 에너지 감소를 구분

## 제공 기록의 해석

`FUNCTIONAL_VALIDATION.json`과 `HDL_VALIDATION.json`은 어셈블리와 기계어의 기능 검증 기록. 실행 모델은 한 클럭에 한 명령을 처리하는 학습용 모델이며, clock edge 개수는 instruction count와 같음.

해당 HDL 파일은 simulation-only 인터프리터. 실제 합성할 CPU가 아니므로 이 파일에 대한 합성·전력 보고서를 프로젝트 CPU PPA로 제출하지 않을 것.

최종 프로젝트의 제어유닛·TOP 연결·합성용 범위와 공식 채점 덱을 확정한 뒤 실제 기준 CPU의 PPA를 측정. 현재 상태에서 면적이나 전력 수치를 임의로 채우지 않을 것.
