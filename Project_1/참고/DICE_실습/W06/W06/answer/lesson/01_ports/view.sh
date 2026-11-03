#!/usr/bin/env bash
# 방금 실행한 시뮬레이션이 PASS일 때 파형을 엽니다.
verdi_sub --fsdb build/ports.fsdb --filelist filelist.f --top tb_ports
