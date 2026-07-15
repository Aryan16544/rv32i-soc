# =============================================================================
# Portable setup script for rv32i_soc_full_tb simulation in Vivado/XSim
# Usage inside Vivado:
#   source setup_sim.tcl
# =============================================================================

set repo_root [file normalize [file dirname [info script]]]
set tb_file   [file join $repo_root rv32i_soc_full_tb.v]
set hdr_file  [file join $repo_root test_expected.vh]
set mem_file  [file join $repo_root rv32i_test_program.mem]

set project_obj [current_project -quiet]
if {$project_obj eq ""} {
    error "Open a Vivado project before sourcing setup_sim.tcl"
}

set include_dirs [list \
    [file join $repo_root core] \
    [file join $repo_root soc] \
    [file join $repo_root peripherals] \
]
set_property include_dirs $include_dirs [get_filesets sources_1]
set_property include_dirs $include_dirs [get_filesets sim_1]

catch {close_sim}

set_property SOURCE_SET sources_1 [get_filesets sim_1]
foreach file_to_add [list $tb_file $hdr_file $mem_file] {
    if {[llength [get_files -quiet $file_to_add]] == 0} {
        add_files -fileset sim_1 -norecurse $file_to_add
    }
}

set_property top rv32i_soc_full_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

launch_simulation
run 300us

puts "============================================================"
puts " Simulation complete. Check the Tcl console for PASS/FAIL."
puts "============================================================"
