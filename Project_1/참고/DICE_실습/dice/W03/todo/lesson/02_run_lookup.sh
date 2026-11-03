#!/usr/bin/env bash
# 이 파일이 있는 폴더에서 실행하세요. 기존 RTL을 컴파일하고 검사합니다.
mkdir -p build/lookup
mkdir -p logs
vcs_queue --fsdb -full64 -timescale=1ns/1ps -f 02_lookup.f -top tb_lookup -Mdir=build/lookup/csrc -o build/lookup/simv -l logs/lookup.log -R
