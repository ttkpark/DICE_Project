#!/usr/bin/env bash
# 먼저 01_run_alu_check.sh를 성공적으로 실행하세요.
verdi_sub --fsdb build/alu_check.fsdb --filelist alu_check.f --top tb_alu_check # 같은 소스와 이번 실행의 파형을 함께 보기
