#!/usr/bin/env bash
# 먼저 같은 번호의 run 스크립트를 실행한 뒤 파형을 여세요.
verdi_sub --fsdb build/fix/waves.fsdb --filelist 06_fix.f --top tb_fix
