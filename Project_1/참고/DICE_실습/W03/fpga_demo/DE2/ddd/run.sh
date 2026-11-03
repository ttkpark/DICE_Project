#!/usr/bin/env bash

# 1. 전에 실행하면서 생긴 결과 폴더를 지웁니다.
rm -rf build logs

# 2. 새 결과 폴더와 로그 폴더를 만듭니다.
mkdir -p build logs

# 3. filelist.f에 적힌 Verilog 파일을 컴파일하고 실행합니다.
#    화면에 보이는 내용은 logs/vcs.log에도 똑같이 저장됩니다.
vcs_queue -full64 -f filelist.f -o build/simv -R |& tee logs/vcs.log
