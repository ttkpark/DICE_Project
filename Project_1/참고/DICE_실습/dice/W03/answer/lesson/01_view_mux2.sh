#!/usr/bin/env bash
# 먼저 같은 번호의 run 스크립트를 실행한 뒤 파형을 여세요.
verdi_sub --fsdb build/mux2/waves.fsdb --filelist 01_mux2.f --top tb_mux2
