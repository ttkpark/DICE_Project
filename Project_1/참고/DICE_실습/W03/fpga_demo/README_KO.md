# W03 예비보고서: 보드에 맞는 한 자리 표시 예제

먼저 보드 모델명과 FPGA 칩의 전체 부품명을 확인합니다. 아래에서 본인 보드에 맞는 폴더 하나만 선택합니다. 이 상위 폴더는 안내용이며 실행 프로젝트가 없습니다.

압축은 새 빈 폴더에 풉니다. 예전 W03 폴더 위에 덮어 풀면 이전 프로젝트가 남을 수 있으므로 기존 실습 파일은 보존하고 새 예제와 구분합니다.

| 보드 / FPGA | 예제와 실행 안내 | Quartus 프로젝트 |
|---|---|---|
| 원래 DE2 / EP2C35F672C6 | [DE2/README_KO.md](DE2/README_KO.md) | DE2/W03_HEX_DEMO_DE2.qpf |
| DE2-115 / EP4CE115F29C7 | [DE2_115/README_KO.md](DE2_115/README_KO.md) | DE2_115/W03_HEX_DEMO_DE2_115.qpf |

DE2-115 예제는 JP7 기본 2.5V 설정에서 사용합니다. 두 보드의 QSF·핀·전압·SOF를 섞지 않습니다. 다른 부품이나 설정은 자동 지원하지 않으므로 불확실하면 조교에게 문의합니다.

두 프로젝트의 RTL 최상위 이름은 모두 `W03_HEX_DEMO`입니다. 프로젝트 이름은 보드를 구분하기 위한 이름이며, 생성되는 파일은 각각 `output_files/W03_HEX_DEMO_DE2.sof`, `output_files/W03_HEX_DEMO_DE2_115.sof`입니다. 선택한 폴더에서 새로 만든 파일만 프로그램합니다.

## 공식 설명서도 각각 선택

수업자료와 별도로 배포하는 `W03_보드매뉴얼` 폴더에서 해당 PDF를 읽습니다. 서버 코드 압축에는 PDF가 들어 있지 않습니다.

- 원래 DE2: `DE2_User_Manual.pdf` — [제조사 공식 설명서](https://www.terasic.com.tw/cgi-bin/page/archive_download.pl?Language=English&No=30&FID=9b745effb0bc150def558e8927537652)
- DE2-115: `DE2_115_User_Manual.pdf` — [제조사 공식 설명서](https://www.terasic.com.tw/attachment/archive/502/DE2_115_User_manual.pdf)

## 할 일

선택한 폴더에서 VCS·Verdi로 검사한 뒤 해당 Quartus 프로젝트를 새로 컴파일하여 보드에 프로그램합니다. 입력 0·1·8·9·10을 넣어 0·1·8·9·소등을 관찰합니다. 보드·FPGA 이름, 프로젝트, 수정한 설정, Programmer 완료 화면, 본인 보드의 숫자 8 사진과 실제 관찰표를 기초 조사와 함께 A4 1쪽에 정리합니다.

전체 발제는 `../W03_예비보고서_발제와_작성예시.txt`, 선택 기준은 [BOARD_SELECTION_KO.md](BOARD_SELECTION_KO.md)를 참고합니다. 두 예제는 예비보고서의 한 자리 표시용이며 수업 중 두 자리 가산기 Checkpoint와 별도입니다. 실제 보드 검증 완료 기록이 아니므로 학생이 자신의 실행 결과를 확인합니다.
