# =============================================================================
# Create a clean Vivado project from the active source tree
# Usage:
#   vivado -mode batch -source scripts/create_vivado_project.tcl
# =============================================================================

set script_dir [file normalize [file dirname [info script]]]
set repo_root [file normalize [file join $script_dir ".."]]
set project_dir [file join $repo_root build vivado]
set project_name rv32i_soc
set default_mem [file join $repo_root soc software hello.mem]

file mkdir $project_dir
if {![file exists $default_mem]} {
    error "Default program image not found: $default_mem"
}
file copy -force $default_mem [file join $project_dir program.mem]

create_project $project_name $project_dir -force -part xc7a12tcpg238-1
set_property target_language Verilog [current_project]

set include_dirs [list \
    [file join $repo_root core] \
    [file join $repo_root soc] \
    [file join $repo_root peripherals] \
]
set_property include_dirs $include_dirs [get_filesets sources_1]
set_property include_dirs $include_dirs [get_filesets sim_1]

set source_files [list \
    [file join $repo_root core rv32i_defines.vh] \
    [file join $repo_root core alu.v] \
    [file join $repo_root core control_unit.v] \
    [file join $repo_root core decode_stage.v] \
    [file join $repo_root core execute_stage.v] \
    [file join $repo_root core fetch_stage.v] \
    [file join $repo_root core hazard_unit.v] \
    [file join $repo_root core memory_stage.v] \
    [file join $repo_root core register_file.v] \
    [file join $repo_root core rv32i_core.v] \
    [file join $repo_root core writeback_stage.v] \
    [file join $repo_root peripherals fifo.v] \
    [file join $repo_root peripherals uart_tx.v] \
    [file join $repo_root peripherals uart_rx.v] \
    [file join $repo_root peripherals uart_axi.v] \
    [file join $repo_root peripherals uart_tx_simple.v] \
    [file join $repo_root soc soc_map.vh] \
    [file join $repo_root soc rv32i_soc.v] \
    [file join $repo_root soc soc_axi_adapter.v] \
    [file join $repo_root soc soc_bram_dmem.v] \
    [file join $repo_root soc soc_bram_imem.v] \
    [file join $repo_root soc soc_gpio.v] \
    [file join $repo_root soc soc_interconnect.v] \
    [file join $repo_root soc soc_timer.v] \
    [file join $repo_root soc fpga_top.v] \
    [file join $project_dir program.mem] \
]
add_files -fileset sources_1 -norecurse $source_files

add_files -fileset constrs_1 -norecurse [file join $repo_root constraints urbana.xdc]

set sim_files [list \
    [file join $repo_root rv32i_soc_full_tb.v] \
    [file join $repo_root soc_verification_tb.v] \
    [file join $repo_root test_expected.vh] \
    [file join $repo_root rv32i_test_program.mem] \
]
add_files -fileset sim_1 -norecurse $sim_files

set_property top fpga_top [get_filesets sources_1]
set_property top rv32i_soc_full_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created Vivado project at $project_dir"
puts "Default FPGA image staged as $project_dir/program.mem"
puts "Simulation top is rv32i_soc_full_tb"

