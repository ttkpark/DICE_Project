#!/usr/bin/env bash
# 이 파일이 있는 폴더에서 실행하세요. 기존 RTL을 컴파일하고 검사합니다.
mkdir -p build/w03_top
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 10_w03_top.f -top tb_w03_top -Mdir=build/w03_top/csrc -o build/w03_top/simv -l logs/w03_top.log -R
