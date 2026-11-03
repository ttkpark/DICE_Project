#!/usr/bin/env bash

# 각 Verilog 파일의 AUTOARG와 AUTOINST를 차례로 갱신합니다.
emacs --batch rtl/09_bcd_to_7seg.v -f verilog-batch-auto
emacs --batch rtl/W03_HEX_DEMO.v -f verilog-batch-auto
emacs --batch sim/tb_W03_HEX_DEMO.v -f verilog-batch-auto

echo "AUTO 갱신 완료"
