// =============================================================================
// Execute (EX) Stage
// Industry-Level Implementation with ALU and Branch Resolution
// =============================================================================

`include "rv32i_defines.vh"

module execute_stage (
    input wire clk,
    input wire rst_n,
    
    // Control signals
    input wire stall,
    
    // Input from ID stage
    input wire [31:0] id_ex_pc,
    input wire [31:0] id_ex_rs1_data,
    input wire [31:0] id_ex_rs2_data,
    input wire [31:0] id_ex_imm,
    input wire [4:0] id_ex_rs1,
    input wire [4:0] id_ex_rs2,
    input wire [4:0] id_ex_rd,
    input wire [3:0] id_ex_alu_op,
    input wire id_ex_alu_src_a,
    input wire id_ex_alu_src_b,
    input wire id_ex_mem_read,
    input wire id_ex_mem_write,
    input wire [1:0] id_ex_mem_size,
    input wire id_ex_mem_unsigned,
    input wire id_ex_reg_write,
    input wire [1:0] id_ex_wb_sel,
    input wire id_ex_branch,
    input wire id_ex_jump,
    input wire id_ex_jalr,
    input wire [2:0] id_ex_branch_type,
    input wire id_ex_valid,
    
    // Forwarding inputs
    input wire [1:0] forward_a,
    input wire [1:0] forward_b,
    input wire [31:0] mem_forward_data,
    input wire [31:0] wb_forward_data,
    
    // Branch/Jump outputs
    output reg branch_taken,
    output reg [31:0] branch_target,
    
    // Outputs to MEM stage (pipeline register)
    output reg [31:0] ex_mem_alu_result,
    output reg [31:0] ex_mem_rs2_data,
    output reg [31:0] ex_mem_pc_plus_4,
    output reg [4:0] ex_mem_rd,
    output reg ex_mem_mem_read,
    output reg ex_mem_mem_write,
    output reg [1:0] ex_mem_mem_size,
    output reg ex_mem_mem_unsigned,
    output reg ex_mem_reg_write,
    output reg [1:0] ex_mem_wb_sel,
    output reg ex_mem_valid
);

    // Forwarded operands
    reg [31:0] operand_a_fwd;
    reg [31:0] operand_b_fwd;
    
    // ALU inputs after mux selection
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;
    
    // ALU outputs
    wire [31:0] alu_result;
    wire alu_zero;
    wire alu_negative;
    wire alu_carry;
    wire alu_overflow;
    
    // PC + 4
    wire [31:0] pc_plus_4 = id_ex_pc + 4;
    
    // -------------------------------------------------------------------------
    // Forwarding Mux for Operand A
    // -------------------------------------------------------------------------
    always @(*) begin
        case (forward_a)
            2'b00: operand_a_fwd = id_ex_rs1_data;
            2'b01: operand_a_fwd = mem_forward_data;
            2'b10: operand_a_fwd = wb_forward_data;
            default: operand_a_fwd = id_ex_rs1_data;
        endcase
    end
    
    // -------------------------------------------------------------------------
    // Forwarding Mux for Operand B
    // -------------------------------------------------------------------------
    always @(*) begin
        case (forward_b)
            2'b00: operand_b_fwd = id_ex_rs2_data;
            2'b01: operand_b_fwd = mem_forward_data;
            2'b10: operand_b_fwd = wb_forward_data;
            default: operand_b_fwd = id_ex_rs2_data;
        endcase
    end
    
    // -------------------------------------------------------------------------
    // ALU Input Selection
    // -------------------------------------------------------------------------
    assign alu_in_a = id_ex_alu_src_a ? id_ex_pc : operand_a_fwd;
    assign alu_in_b = id_ex_alu_src_b ? id_ex_imm : operand_b_fwd;
    
    // -------------------------------------------------------------------------
    // ALU Instantiation
    // -------------------------------------------------------------------------
    alu alu_inst (
        .operand_a(alu_in_a),
        .operand_b(alu_in_b),
        .alu_op(id_ex_alu_op),
        .result(alu_result),
        .zero(alu_zero),
        .negative(alu_negative),
        .carry(alu_carry),
        .overflow(alu_overflow)
    );
    
    // -------------------------------------------------------------------------
    // Branch Resolution
    // -------------------------------------------------------------------------
    reg branch_condition;
    
    always @(*) begin
        case (id_ex_branch_type)
            `BRANCH_EQ:  branch_condition = (operand_a_fwd == operand_b_fwd);
            `BRANCH_NE:  branch_condition = (operand_a_fwd != operand_b_fwd);
            `BRANCH_LT:  branch_condition = ($signed(operand_a_fwd) < $signed(operand_b_fwd));
            `BRANCH_GE:  branch_condition = ($signed(operand_a_fwd) >= $signed(operand_b_fwd));
            `BRANCH_LTU: branch_condition = (operand_a_fwd < operand_b_fwd);
            `BRANCH_GEU: branch_condition = (operand_a_fwd >= operand_b_fwd);
            default:     branch_condition = 1'b0;
        endcase
    end
    
    // -------------------------------------------------------------------------
    // Branch/Jump Control
    // -------------------------------------------------------------------------
    always @(*) begin
        if (id_ex_jump) begin
            // JAL
            branch_taken = 1'b1;
            branch_target = id_ex_pc + id_ex_imm;
        end else if (id_ex_jalr) begin
            // JALR
            branch_taken = 1'b1;
            branch_target = (operand_a_fwd + id_ex_imm) & ~32'b1;  // Clear LSB
        end else if (id_ex_branch && branch_condition) begin
            // Conditional branch
            branch_taken = 1'b1;
            branch_target = id_ex_pc + id_ex_imm;
        end else begin
            branch_taken = 1'b0;
            branch_target = 32'b0;
        end
    end
    
    // -------------------------------------------------------------------------
    // Pipeline Register: EX/MEM
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_result <= 32'b0;
            ex_mem_rs2_data <= 32'b0;
            ex_mem_pc_plus_4 <= 32'b0;
            ex_mem_rd <= 5'b0;
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_size <= 2'b0;
            ex_mem_mem_unsigned <= 1'b0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_wb_sel <= 2'b0;
            ex_mem_valid <= 1'b0;
        end else if (!stall) begin
            ex_mem_alu_result <= alu_result;
            ex_mem_rs2_data <= operand_b_fwd;
            ex_mem_pc_plus_4 <= pc_plus_4;
            ex_mem_rd <= id_ex_rd;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_size <= id_ex_mem_size;
            ex_mem_mem_unsigned <= id_ex_mem_unsigned;
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_wb_sel <= id_ex_wb_sel;
            ex_mem_valid <= id_ex_valid;
        end
    end

endmodule
