# 수업 서버의 셀 라이브러리 (W06 checkpoint 와 같은 경로)
# corner = R1.3a~R1.4 명세 (R1.4 synth/library_setup.tcl 과 같은 DB) "PPA 의 CPU timing 은 SAED32 RVT SS 0.95 V 125 C 에서 비교" (Project1_INT8_SDC_적용안내_20261023.md)
# 서버에서 먼저 확인: ls /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/ | grep ss0p95v125c
set CORNER ss0p95v125c
set_app_var target_library /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_${CORNER}.db
set_app_var link_library "* $target_library"
