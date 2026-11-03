#!/usr/bin/env bash
# 이 파일이 있는 폴더에서 실행하세요. 기존 RTL을 컴파일하고 검사합니다.
mkdir -p build/mux2
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 01_mux2.f -top tb_mux2 -Mdir=build/mux2/csrc -o build/mux2/simv -l logs/mux2.log -R
