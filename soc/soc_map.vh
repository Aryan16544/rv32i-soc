// =============================================================================
// SoC Memory Map (Final Standard)
// =============================================================================
`ifndef SOC_MAP_VH
`define SOC_MAP_VH

// Memory Regions
`define BOOT_ROM_BASE   32'h0000_0000
`define BOOT_ROM_SIZE   32'h0000_1000  // 4KB
`define BOOT_ROM_MASK   32'hFFFF_F000

`define MAIN_RAM_BASE   32'h1000_0000
`define MAIN_RAM_SIZE   32'h0001_0000  // 64KB
`define MAIN_RAM_MASK   32'hFFFF_0000

// Peripherals
`define GPIO_BASE       32'h2000_0000
`define GPIO_SIZE       32'h0000_1000
`define GPIO_MASK       32'hFFFF_F000

`define UART_BASE       32'h3000_0000
`define UART_SIZE       32'h0000_1000
`define UART_MASK       32'hFFFF_F000

`define TIMER_BASE      32'h4000_0000
`define TIMER_SIZE      32'h0000_1000
`define TIMER_MASK      32'hFFFF_F000

`endif // SOC_MAP_VH
