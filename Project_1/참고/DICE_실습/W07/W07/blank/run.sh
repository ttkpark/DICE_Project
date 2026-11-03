#!/usr/bin/env bash
# answer / todo / blank 폴더에서 실행
mkdir -p build
mkdir -p logs
# 기존 W06 wrapper 사용. 실행 후 로그에서 실제 PASS 확인
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f filelist.f -top tb_controller -Mdir=build/csrc -o build/simv -l logs/sim.log -R
