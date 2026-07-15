// =============================================================================
// RV32I Processor Definitions
// Industry-Level RISC-V Implementation
// =============================================================================

`ifndef RV32I_DEFINES_VH
`define RV32I_DEFINES_VH

// -----------------------------------------------------------------------------
// Opcode Definitions (inst[6:0])
// -----------------------------------------------------------------------------
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_JAL      7'b1101111
`define OPCODE_JALR     7'b1100111
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_STORE    7'b0100011
`define OPCODE_OP_IMM   7'b0010011
`define OPCODE_OP       7'b0110011
`define OPCODE_FENCE    7'b0001111
`define OPCODE_SYSTEM   7'b1110011

// -----------------------------------------------------------------------------
// Funct3 Definitions
// -----------------------------------------------------------------------------
// Branch instructions
`define FUNCT3_BEQ      3'b000
`define FUNCT3_BNE      3'b001
`define FUNCT3_BLT      3'b100
`define FUNCT3_BGE      3'b101
`define FUNCT3_BLTU     3'b110
`define FUNCT3_BGEU     3'b111

// Load instructions
`define FUNCT3_LB       3'b000
`define FUNCT3_LH       3'b001
`define FUNCT3_LW       3'b010
`define FUNCT3_LBU      3'b100
`define FUNCT3_LHU      3'b101

// Store instructions
`define FUNCT3_SB       3'b000
`define FUNCT3_SH       3'b001
`define FUNCT3_SW       3'b010

// ALU operations (OP-IMM and OP)
`define FUNCT3_ADD_SUB  3'b000
`define FUNCT3_SLL      3'b001
`define FUNCT3_SLT      3'b010
`define FUNCT3_SLTU     3'b011
`define FUNCT3_XOR      3'b100
`define FUNCT3_SRL_SRA  3'b101
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111

// -----------------------------------------------------------------------------
// Funct7 Definitions
// -----------------------------------------------------------------------------
`define FUNCT7_ADD      7'b0000000
`define FUNCT7_SUB      7'b0100000
`define FUNCT7_SRL      7'b0000000
`define FUNCT7_SRA      7'b0100000

// -----------------------------------------------------------------------------
// ALU Operation Codes
// -----------------------------------------------------------------------------
`define ALU_ADD         4'b0000
`define ALU_SUB         4'b0001
`define ALU_AND         4'b0010
`define ALU_OR          4'b0011
`define ALU_XOR         4'b0100
`define ALU_SLL         4'b0101
`define ALU_SRL         4'b0110
`define ALU_SRA         4'b0111
`define ALU_SLT         4'b1000
`define ALU_SLTU        4'b1001
`define ALU_PASS_B      4'b1010

// -----------------------------------------------------------------------------
// Branch Condition Codes
// -----------------------------------------------------------------------------
`define BRANCH_EQ       3'b000
`define BRANCH_NE       3'b001
`define BRANCH_LT       3'b100
`define BRANCH_GE       3'b101
`define BRANCH_LTU      3'b110
`define BRANCH_GEU      3'b111

// -----------------------------------------------------------------------------
// Memory Access Sizes
// -----------------------------------------------------------------------------
`define MEM_SIZE_BYTE   2'b00
`define MEM_SIZE_HALF   2'b01
`define MEM_SIZE_WORD   2'b10

// -----------------------------------------------------------------------------
// AXI-Lite Response Codes
// -----------------------------------------------------------------------------
`define AXI_RESP_OKAY   2'b00
`define AXI_RESP_EXOKAY 2'b01
`define AXI_RESP_SLVERR 2'b10
`define AXI_RESP_DECERR 2'b11

// -----------------------------------------------------------------------------
// System Parameters
// -----------------------------------------------------------------------------
`define DATA_WIDTH      32
`define ADDR_WIDTH      32
`define REG_ADDR_WIDTH  5
`define NUM_REGS        32

// Shared memory-map defaults.
// Prefer soc/soc_map.vh for the active SoC address map.
`ifndef IMEM_BASE
`define IMEM_BASE       32'h0000_0000
`endif
`ifndef IMEM_SIZE
`define IMEM_SIZE       32'h0000_1000  // 4KB
`endif
`ifndef DMEM_BASE
`define DMEM_BASE       32'h1000_0000
`endif
`ifndef DMEM_SIZE
`define DMEM_SIZE       32'h0001_0000  // 64KB
`endif
`ifndef GPIO_BASE
`define GPIO_BASE       32'h2000_0000
`endif
`ifndef GPIO_SIZE
`define GPIO_SIZE       32'h0000_1000  // 4KB
`endif
`ifndef UART_BASE
`define UART_BASE       32'h3000_0000
`endif
`ifndef UART_SIZE
`define UART_SIZE       32'h0000_1000  // 4KB
`endif
`ifndef TIMER_BASE
`define TIMER_BASE      32'h4000_0000
`endif
`ifndef TIMER_SIZE
`define TIMER_SIZE      32'h0000_1000  // 4KB
`endif

// UART Register Offsets
`define UART_TX_DATA    8'h00
`define UART_RX_DATA    8'h04
`define UART_STATUS     8'h08
`define UART_CTRL       8'h0C
`define UART_BAUD_DIV   8'h10

`endif // RV32I_DEFINES_VH
