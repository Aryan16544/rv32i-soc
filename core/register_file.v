// =============================================================================
// Register File - 32x32-bit General Purpose Registers
// Industry-Level Implementation with 2 Read Ports + 1 Write Port
// =============================================================================

`include "rv32i_defines.vh"

module register_file (
    input wire clk,
    input wire rst_n,
    
    // Read Port 1
    input wire [4:0] rs1_addr,
    output wire [31:0] rs1_data,
    
    // Read Port 2
    input wire [4:0] rs2_addr,
    output wire [31:0] rs2_data,
    
    // Write Port
    input wire wr_en,
    input wire [4:0] rd_addr,
    input wire [31:0] rd_data
);

    // Register array: x0-x31 (x0 is hardwired to 0)
    reg [31:0] registers [1:31];
    
    // For simulation - initialize registers to zero
    integer i;
    initial begin
        for (i = 1; i < 32; i = i + 1) begin
            registers[i] = 32'b0;
        end
    end
    
    // Asynchronous read for rs1 with write-to-read bypass
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : 
                      (wr_en && (rd_addr == rs1_addr)) ? rd_data : 
                      registers[rs1_addr];
    
    // Asynchronous read for rs2 with write-to-read bypass
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : 
                      (wr_en && (rd_addr == rs2_addr)) ? rd_data : 
                      registers[rs2_addr];
    
    // Synchronous write (synthesis-friendly - no reset loop)
    // Registers are initialized via initial block for simulation
    // For FPGA synthesis, registers will power up to zero or unknown state
    // and will be written during program execution
    always @(posedge clk) begin
        if (wr_en && rd_addr != 5'b0) begin
            // Write to register (skip x0)
            registers[rd_addr] <= rd_data;
        end
    end

endmodule
