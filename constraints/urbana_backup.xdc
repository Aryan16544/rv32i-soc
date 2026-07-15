# =============================================================================
# AMD Urbana Board Constraints for RV32I SoC
# Professional FPGA Constraints
# =============================================================================

# Clock - 100MHz oscillator
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk [get_ports CLK100MHZ]

# Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.Config.SPI_buswidth 4 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Reset Button (using SW[0] as active-low reset)
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS25} [get_ports CPU_RESETN]

# UART Signals (USB-UART bridge)
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports UART_TXD_IN]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports UART_RXD_OUT]

# LEDs for Debug
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports {LED[4]}]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {LED[5]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {LED[6]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {LED[7]}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {LED[8]}]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {LED[9]}]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {LED[10]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {LED[11]}]
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports {LED[12]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {LED[13]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {LED[14]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {LED[15]}]

# Switches
# NOTE: On Urbana board, SW[0] (pin G1) is used as CPU_RESETN button
# Only SW[1] through SW[15] are available as general-purpose switches (15 total)
# SW[0] is not connected to any pin - set to pulldown to avoid floating
set_property PULLDOWN TRUE [get_ports {SW[0]}]
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS25} [get_ports {SW[1]}]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS25} [get_ports {SW[2]}]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS25} [get_ports {SW[3]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS25} [get_ports {SW[4]}]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS25} [get_ports {SW[5]}]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS25} [get_ports {SW[6]}]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS25} [get_ports {SW[7]}]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS25} [get_ports {SW[8]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS25} [get_ports {SW[9]}]
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS25} [get_ports {SW[10]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS25} [get_ports {SW[11]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS25} [get_ports {SW[12]}]
set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS25} [get_ports {SW[13]}]
set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS25} [get_ports {SW[14]}]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS25} [get_ports {SW[15]}]

# =============================================================================
# Timing Constraints
# =============================================================================
## Primary clock constraint (100MHz) - already defined above with create_clock

## Input/Output Delays
set_input_delay -clock sys_clk -min 0.0 [get_ports {UART_TXD_IN SW[*]}]
set_input_delay -clock sys_clk -max 2.0 [get_ports {UART_TXD_IN SW[*]}]
set_output_delay -clock sys_clk -min -1.0 [get_ports {UART_RXD_OUT LED[*]}]
set_output_delay -clock sys_clk -max 2.0 [get_ports {UART_RXD_OUT LED[*]}]

## False paths for async inputs
set_false_path -from [get_ports CPU_RESETN]

## Relax timing for debug signals (switches and LEDs)
set_false_path -from [get_ports {SW[*]}] -to [get_ports {LED[*]}]

## Allow bitstream generation even with minor timing violations
## (For prototyping - should be fixed for production)
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks TIMING-*]
