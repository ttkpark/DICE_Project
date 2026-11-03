#!/usr/bin/env bash
# 이 파일이 있는 폴더에서 실행하세요. 기존 RTL을 컴파일하고 검사합니다.
mkdir -p build/bcd_to_7seg
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 09_bcd_to_7seg.f -top tb_bcd_to_7seg -Mdir=build/bcd_to_7seg/csrc -o build/bcd_to_7seg/simv -l logs/bcd_to_7seg.log -R
