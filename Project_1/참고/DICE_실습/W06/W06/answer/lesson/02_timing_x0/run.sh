#!/usr/bin/env bash
# 이 파일이 있는 폴더에서 실행합니다.
mkdir -p build
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f filelist.f -top tb_timing_x0 -Mdir=build/csrc -o build/simv -l build/run.log -R
