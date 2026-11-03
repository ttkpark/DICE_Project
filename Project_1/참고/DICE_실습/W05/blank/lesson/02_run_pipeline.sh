#!/usr/bin/env bash
set -euo pipefail # 오류가 나면 중단하여 이전 결과를 성공으로 취급하지 않습니다.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")" # 어디에서 호출해도 이 스크립트의 폴더로 이동합니다.
mkdir -p build/02_pipeline # 이번 예제의 실행 파일 폴더를 준비합니다.
mkdir -p logs # 컴파일·시뮬레이션 로그 폴더를 준비합니다.
rm -f build/02_pipeline.passed build/02_pipeline.fsdb build/02_pipeline.vcd logs/02_pipeline.log # 이전 성공 표시와 파형·로그를 지웁니다.
if ! command -v vcs_queue >/dev/null 2>&1; then # wrapper 설치 여부를 먼저 확인합니다.
    echo "오류: vcs_queue가 없습니다. 수업 서버에서 실행하거나 조교에게 환경을 확인하세요." >&2 # RTL 오류와 구분합니다.
    exit 2 # 서버 환경 오류로 종료합니다.
fi
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 02_pipeline.f -top tb_02_pipeline -Mdir=build/02_pipeline/csrc -o build/02_pipeline/simv -l logs/02_pipeline.log -R # 큐에서 새로 컴파일·실행하고 FSDB를 기록합니다.
if ! grep -Fxq 'W05 PIPELINE PASS (6/6)' logs/02_pipeline.log; then # 이번 로그의 최종 PASS를 확인합니다.
    echo "오류: 최종 PASS가 없습니다. logs/02_pipeline.log의 첫 FAIL 또는 컴파일 오류를 확인하세요." >&2 # 검사 실패 위치를 안내합니다.
    exit 1 # PASS 없는 실행은 성공으로 표시하지 않습니다.
fi
if [[ ! -s build/02_pipeline.fsdb || ! -s build/02_pipeline.vcd ]]; then # wrapper의 실제 파형 생성도 확인합니다.
    echo "오류: 새 FSDB/VCD가 없습니다. 조교에게 wrapper의 DUMP_FSDB 설정을 확인하세요." >&2 # 파형 환경 오류를 안내합니다.
    exit 1 # 파형이 없으면 성공 표시를 남기지 않습니다.
fi
touch build/02_pipeline.passed # 이번 실행이 모든 조건을 통과한 경우에만 표시합니다.
echo "완료: 02_view_pipeline.sh로 이번 실행의 파형을 여세요." # 다음 작업을 안내합니다.
