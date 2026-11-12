# Common course corner. Teams must not substitute another library/corner.
# This path follows the W06/W07 course server PDK installation.
set P1_STD_CELL_DB /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ss0p95v125c.db
if {![file isfile $P1_STD_CELL_DB]} {
    error "P1: SAED32 RVT SS 0.95V 125C DB missing. Ask TA to verify the server PDK path; do not substitute TT."
}
set_app_var target_library [list $P1_STD_CELL_DB]
set_app_var link_library [concat * $target_library]
