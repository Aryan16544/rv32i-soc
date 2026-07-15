// =============================================================================
// Instruction Fetch (IF) Stage
// Industry-Level Implementation with PC Management
// =============================================================================

`include "rv32i_defines.vh"

module fetch_stage (
    input wire clk,
    input wire rst_n,
    
    // Control signals
    input wire stall,
    input wire branch_taken,
    input wire [31:0] branch_target,
    
    // Instruction memory interface (AXI-Lite Master)
    output reg [31:0] imem_addr,
    output reg imem_valid,
    input wire [31:0] imem_rdata,
    input wire imem_ready,
    
    // Output to ID stage
    output reg [31:0] if_id_pc,
    output reg [31:0] if_id_instruction,
    output reg if_id_valid
);

    // Program Counter
    reg [31:0] pc;
    reg [31:0] pc_next;
    
    // PC update logic
    always @(*) begin
        if (branch_taken) begin
            pc_next = branch_target;
        end else if (!stall && imem_ready) begin
            pc_next = pc + 4;
        end else begin
            pc_next = pc;
        end
    end
    
    // PC register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h0000_0000;  // Reset vector
        end else begin
            pc <= pc_next;
        end
    end
    
    // Instruction memory request
    always @(*) begin
        imem_addr = pc;
        imem_valid = !stall;
    end
    
    // Pipeline register: IF/ID
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_pc <= 32'b0;
            if_id_instruction <= 32'h0000_0013;  // NOP (ADDI x0, x0, 0)
            if_id_valid <= 1'b0;
        end else if (branch_taken) begin
            // Flush on branch
            if_id_pc <= 32'b0;
            if_id_instruction <= 32'h0000_0013;  // NOP
            if_id_valid <= 1'b0;
        end else if (!stall && imem_ready) begin
            if_id_pc <= pc;
            if_id_instruction <= imem_rdata;
            if_id_valid <= 1'b1;
        end
        // else hold current values when stalled
    end

endmodule
