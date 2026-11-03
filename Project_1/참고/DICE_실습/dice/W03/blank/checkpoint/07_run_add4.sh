#!/usr/bin/env bash
# 이 파일이 있는 폴더에서 실행하세요. 기존 RTL을 컴파일하고 검사합니다.
mkdir -p build/add4
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 07_add4.f -top tb_add4 -Mdir=build/add4/csrc -o build/add4/simv -l logs/add4.log -R
