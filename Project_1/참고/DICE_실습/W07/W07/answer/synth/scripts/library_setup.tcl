# W06 서버 경로. 배포 전 파일 존재 여부 확인
set_app_var target_library /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_tt1p05v25c.db
set_app_var link_library "* $target_library"
