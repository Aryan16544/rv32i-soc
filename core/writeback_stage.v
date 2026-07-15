// =============================================================================
// Writeback (WB) Stage
// Industry-Level Implementation with Result Multiplexing
// =============================================================================

module writeback_stage (
    // Input from MEM stage
    input wire [31:0] mem_wb_result,
    input wire [31:0] mem_wb_pc_plus_4,
    input wire [4:0] mem_wb_rd,
    input wire mem_wb_reg_write,
    input wire [1:0] mem_wb_wb_sel,
    input wire mem_wb_valid,
    
    // Outputs to register file (in ID stage)
    output wire [31:0] wb_data,
    output wire [4:0] wb_rd,
    output wire wb_reg_write
);

    // Writeback data multiplexer
    reg [31:0] wb_data_mux;
    
    always @(*) begin
        case (mem_wb_wb_sel)
            2'b00: wb_data_mux = mem_wb_result;      // ALU result
            2'b01: wb_data_mux = mem_wb_result;      // Memory data (already in result)
            2'b10: wb_data_mux = mem_wb_pc_plus_4;   // PC+4 (for JAL/JALR)
            default: wb_data_mux = mem_wb_result;
        endcase
    end
    
    // Outputs
    assign wb_data = wb_data_mux;
    assign wb_rd = mem_wb_rd;
    assign wb_reg_write = mem_wb_reg_write && mem_wb_valid;

endmodule
