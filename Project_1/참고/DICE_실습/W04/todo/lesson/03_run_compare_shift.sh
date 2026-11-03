#!/usr/bin/env bash
# 이 스크립트가 있는 lesson 폴더에서 실행하세요.
mkdir -p build/03_compare_shift # 실행 파일과 파형 폴더 준비
mkdir -p logs # 로그 폴더 준비
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 03_compare_shift.f -top tb_03_compare_shift -Mdir=build/03_compare_shift/csrc -o build/03_compare_shift/simv -l logs/03_compare_shift.log -R # VCS 큐에서 컴파일·검사하고 VCD·FSDB 저장
