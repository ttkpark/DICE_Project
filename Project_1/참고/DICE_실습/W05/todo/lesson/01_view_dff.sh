#!/usr/bin/env bash
set -euo pipefail # 오류가 나면 중단합니다.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")" # 실행 위치를 소스 폴더로 고정합니다.
if [[ ! -f build/01_dff.passed || ! -s build/01_dff.fsdb ]]; then # 성공한 이번 실행의 파형인지 확인합니다.
    echo "오류: 먼저 bash 01_run_dff.sh을 실행하여 PASS와 새 FSDB를 만드세요." >&2 # 오래된 파형을 열지 않습니다.
    exit 1 # 실행부터 다시 하도록 종료합니다.
fi
if [[ 01_dff.f -nt build/01_dff.passed || 01_run_dff.sh -nt build/01_dff.passed ]]; then # 파일리스트·실행 설정 변경도 감지합니다.
    echo "오류: 실행 설정이 바뀌었습니다. bash 01_run_dff.sh을 다시 실행하세요." >&2 # 재실행을 안내합니다.
    exit 1 # 이전 설정의 파형은 열지 않습니다.
fi
while IFS= read -r source; do # 파일리스트의 소스 갱신 시각을 검사합니다.
    if [[ ! -f "$source" || "$source" -nt build/01_dff.passed ]]; then # 소스가 없거나 실행 뒤 바뀌었는지 확인합니다.
        echo "오류: 소스가 바뀌었습니다. bash 01_run_dff.sh을 다시 실행하세요." >&2 # 최신 결과를 만들도록 안내합니다.
        exit 1 # 이전 소스의 파형은 열지 않습니다.
    fi
done < 01_dff.f
verdi_sub --fsdb build/01_dff.fsdb --filelist 01_dff.f --top tb_01_dff # 같은 소스와 이번 실행의 파형을 엽니다.
