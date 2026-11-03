#!/usr/bin/env bash
# 이 스크립트가 있는 checkpoint 폴더에서 실행하세요.
mkdir -p build/alu_check # 실행 파일과 파형 폴더 준비
mkdir -p logs # 로그 폴더 준비
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f alu_check.f -top tb_alu_check -Mdir=build/alu_check/csrc -o build/alu_check/simv -l logs/alu_check.log -R # VCS 큐에서 컴파일·검사하고 VCD·FSDB 저장
