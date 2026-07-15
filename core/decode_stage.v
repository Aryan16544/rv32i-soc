// =============================================================================
// Instruction Decode (ID) Stage
// Industry-Level Implementation with Register File
// =============================================================================

`include "rv32i_defines.vh"

module decode_stage (
    input wire clk,
    input wire rst_n,
    
    // Input from IF stage
    input wire [31:0] if_id_pc,
    input wire [31:0] if_id_instruction,
    input wire if_id_valid,
    
    // Control signals
    input wire stall,
    input wire flush,
    
    // Writeback from WB stage
    input wire wb_reg_write,
    input wire [4:0] wb_rd,
    input wire [31:0] wb_data,
    
    // Outputs to EX stage (pipeline register)
    output reg [31:0] id_ex_pc,
    output reg [31:0] id_ex_rs1_data,
    output reg [31:0] id_ex_rs2_data,
    output reg [31:0] id_ex_imm,
    output reg [4:0] id_ex_rs1,
    output reg [4:0] id_ex_rs2,
    output reg [4:0] id_ex_rd,
    output reg [3:0] id_ex_alu_op,
    output reg id_ex_alu_src_a,
    output reg id_ex_alu_src_b,
    output reg id_ex_mem_read,
    output reg id_ex_mem_write,
    output reg [1:0] id_ex_mem_size,
    output reg id_ex_mem_unsigned,
    output reg id_ex_reg_write,
    output reg [1:0] id_ex_wb_sel,
    output reg id_ex_branch,
    output reg id_ex_jump,
    output reg id_ex_jalr,
    output reg [2:0] id_ex_branch_type,
    output reg id_ex_valid
);

    // Control signals from control unit
    wire [3:0] alu_op;
    wire alu_src_a;
    wire alu_src_b;
    wire mem_read;
    wire mem_write;
    wire [1:0] mem_size;
    wire mem_unsigned;
    wire reg_write;
    wire [1:0] wb_sel;
    wire branch;
    wire jump;
    wire jalr;
    wire [2:0] branch_type;
    
    // Instruction fields
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [31:0] imm;
    
    // Register file read data
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    
    // Control Unit
    control_unit ctrl (
        .instruction(if_id_instruction),
        .alu_op(alu_op),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .mem_unsigned(mem_unsigned),
        .reg_write(reg_write),
        .wb_sel(wb_sel),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .branch_type(branch_type),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm)
    );
    
    // Register File
    register_file regfile (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1),
        .rs1_data(rs1_data),
        .rs2_addr(rs2),
        .rs2_data(rs2_data),
        .wr_en(wb_reg_write),
        .rd_addr(wb_rd),
        .rd_data(wb_data)
    );
    
    // Pipeline register: ID/EX
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            id_ex_pc <= 32'b0;
            id_ex_rs1_data <= 32'b0;
            id_ex_rs2_data <= 32'b0;
            id_ex_imm <= 32'b0;
            id_ex_rs1 <= 5'b0;
            id_ex_rs2 <= 5'b0;
            id_ex_rd <= 5'b0;
            id_ex_alu_op <= 4'b0;
            id_ex_alu_src_a <= 1'b0;
            id_ex_alu_src_b <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_mem_size <= 2'b0;
            id_ex_mem_unsigned <= 1'b0;
            id_ex_reg_write <= 1'b0;
            id_ex_wb_sel <= 2'b0;
            id_ex_branch <= 1'b0;
            id_ex_jump <= 1'b0;
            id_ex_jalr <= 1'b0;
            id_ex_branch_type <= 3'b0;
            id_ex_valid <= 1'b0;
        end else if (!stall) begin
            id_ex_pc <= if_id_pc;
            id_ex_rs1_data <= rs1_data;
            id_ex_rs2_data <= rs2_data;
            id_ex_imm <= imm;
            id_ex_rs1 <= rs1;
            id_ex_rs2 <= rs2;
            id_ex_rd <= rd;
            id_ex_alu_op <= alu_op;
            id_ex_alu_src_a <= alu_src_a;
            id_ex_alu_src_b <= alu_src_b;
            id_ex_mem_read <= mem_read;
            id_ex_mem_write <= mem_write;
            id_ex_mem_size <= mem_size;
            id_ex_mem_unsigned <= mem_unsigned;
            id_ex_reg_write <= reg_write;
            id_ex_wb_sel <= wb_sel;
            id_ex_branch <= branch;
            id_ex_jump <= jump;
            id_ex_jalr <= jalr;
            id_ex_branch_type <= branch_type;
            id_ex_valid <= if_id_valid;
        end
    end

endmodule
