#!/usr/bin/env bash
# 이 스크립트가 있는 lesson 폴더에서 실행하세요.
mkdir -p build/02_logic # 실행 파일과 파형 폴더 준비
mkdir -p logs # 로그 폴더 준비
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 02_logic.f -top tb_02_logic -Mdir=build/02_logic/csrc -o build/02_logic/simv -l logs/02_logic.log -R # VCS 큐에서 컴파일·검사하고 VCD·FSDB 저장
