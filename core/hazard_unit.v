// =============================================================================
// Hazard Detection and Forwarding Unit
// Industry-Level Pipeline Hazard Handling
// =============================================================================

module hazard_unit (
    // Decode stage
    input wire [4:0] id_rs1,
    input wire [4:0] id_rs2,
    
    // Execute stage
    input wire [4:0] ex_rs1,
    input wire [4:0] ex_rs2,
    input wire [4:0] ex_rd,
    input wire ex_reg_write,
    input wire ex_mem_read,
    
    // Memory stage
    input wire [4:0] mem_rd,
    input wire mem_reg_write,
    
    // Writeback stage
    input wire [4:0] wb_rd,
    input wire wb_reg_write,
    
    // Branch/Jump control
    input wire branch_taken,
    input wire jump,
    
    // Memory stall
    input wire mem_stall,
    
    // Hazard control outputs
    output reg stall_if,
    output reg stall_id,
    output reg stall_ex,
    output reg flush_id,
    output reg flush_ex,
    output reg [1:0] forward_a,  // 00: no forward, 01: from MEM, 10: from WB
    output reg [1:0] forward_b
);

    // -------------------------------------------------------------------------
    // Load-Use Hazard Detection
    // -------------------------------------------------------------------------
    wire load_use_hazard;
    assign load_use_hazard = ex_mem_read && 
                             ((ex_rd == id_rs1) || (ex_rd == id_rs2)) && 
                             (ex_rd != 5'b0);
    
    // -------------------------------------------------------------------------
    // Pipeline Stall Logic
    // -------------------------------------------------------------------------
    always @(*) begin
        if (mem_stall) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            stall_ex = 1'b1;
        end else if (load_use_hazard) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            stall_ex = 1'b0;
        end else begin
            stall_if = 1'b0;
            stall_id = 1'b0;
            stall_ex = 1'b0;
        end
    end
    
    // -------------------------------------------------------------------------
    // Pipeline Flush Logic (for branches and jumps)
    // -------------------------------------------------------------------------
    always @(*) begin
        if (mem_stall) begin
            flush_id = 1'b0;
            flush_ex = 1'b0;
        end else if (branch_taken || jump) begin
            flush_id = 1'b1;
            flush_ex = 1'b1;
        end else if (load_use_hazard) begin
            flush_id = 1'b0;
            flush_ex = 1'b1;  // Insert bubble in EX stage
        end else begin
            flush_id = 1'b0;
            flush_ex = 1'b0;
        end
    end
    
    // -------------------------------------------------------------------------
    // Data Forwarding Logic for Operand A
    // -------------------------------------------------------------------------
    always @(*) begin
        // Priority: MEM stage > WB stage
        if (mem_reg_write && (mem_rd != 5'b0) && (mem_rd == ex_rs1)) begin
            forward_a = 2'b01;  // Forward from MEM stage
        end else if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == ex_rs1)) begin
            forward_a = 2'b10;  // Forward from WB stage
        end else begin
            forward_a = 2'b00;  // No forwarding
        end
    end
    
    // -------------------------------------------------------------------------
    // Data Forwarding Logic for Operand B
    // -------------------------------------------------------------------------
    always @(*) begin
        // Priority: MEM stage > WB stage
        if (mem_reg_write && (mem_rd != 5'b0) && (mem_rd == ex_rs2)) begin
            forward_b = 2'b01;  // Forward from MEM stage
        end else if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == ex_rs2)) begin
            forward_b = 2'b10;  // Forward from WB stage
        end else begin
            forward_b = 2'b00;  // No forwarding
        end
    end

endmodule
