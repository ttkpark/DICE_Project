#!/usr/bin/env bash
# 이 스크립트가 있는 lesson 폴더에서 실행하세요.
mkdir -p build/01_addsub # 실행 파일과 파형 폴더 준비
mkdir -p logs # 로그 폴더 준비
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 01_addsub.f -top tb_01_addsub -Mdir=build/01_addsub/csrc -o build/01_addsub/simv -l logs/01_addsub.log -R # VCS 큐에서 컴파일·검사하고 VCD·FSDB 저장
