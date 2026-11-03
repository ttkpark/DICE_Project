#!/usr/bin/env bash
# 먼저 같은 번호의 run 스크립트를 실행한 뒤 파형을 여세요.
verdi_sub --fsdb build/bcd_to_7seg/waves.fsdb --filelist 09_bcd_to_7seg.f --top tb_bcd_to_7seg
