#!/usr/bin/env bash
# 방금 실행한 로그가 PASS인지 확인한 뒤 파형 열기
verdi_sub --fsdb build/controller.fsdb --filelist filelist.f --top tb_controller
