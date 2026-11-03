#!/usr/bin/env bash
# 이 파일이 있는 폴더에서 실행하세요. 기존 RTL을 컴파일하고 검사합니다.
mkdir -p build/bin5_to_bcd
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 08_bin5_to_bcd.f -top tb_bin5_to_bcd -Mdir=build/bin5_to_bcd/csrc -o build/bin5_to_bcd/simv -l logs/bin5_to_bcd.log -R
