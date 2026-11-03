# 수업 서버의 셀 라이브러리 (W06 checkpoint 와 같은 경로)
# corner = 계약서 SRAM 기준과 같은 SS 0.95 V 125 C. 조교가 다른 corner 를 지정하면 이 이름만 바꾼다 (예: tt1p05v25c)
set CORNER ss0p95v125c
set_app_var target_library /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_${CORNER}.db
set_app_var link_library "* $target_library"
