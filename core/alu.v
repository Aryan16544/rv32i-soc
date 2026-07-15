// =============================================================================
// Arithmetic Logic Unit (ALU)
// Industry-Level 32-bit ALU for RV32I
// Supports: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
// =============================================================================

`include "rv32i_defines.vh"

module alu (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0] alu_op,
    output reg [31:0] result,
    output wire zero,
    output wire negative,
    output wire carry,
    output wire overflow
);

    wire [31:0] sum;
    wire [31:0] sub_result;
    wire cout;
    
    // Adder/Subtractor
    assign {cout, sum} = operand_a + operand_b;
    assign sub_result = operand_a - operand_b;
    
    // Shift amount (lower 5 bits of operand_b)
    wire [4:0] shamt = operand_b[4:0];
    
    // Signed comparison
    wire signed_lt = ($signed(operand_a) < $signed(operand_b));
    
    // Unsigned comparison
    wire unsigned_lt = (operand_a < operand_b);
    
    // ALU operation decode
    always @(*) begin
        case (alu_op)
            `ALU_ADD:     result = sum;
            `ALU_SUB:     result = sub_result;
            `ALU_AND:     result = operand_a & operand_b;
            `ALU_OR:      result = operand_a | operand_b;
            `ALU_XOR:     result = operand_a ^ operand_b;
            `ALU_SLL:     result = operand_a << shamt;
            `ALU_SRL:     result = operand_a >> shamt;
            `ALU_SRA:     result = $signed(operand_a) >>> shamt;
            `ALU_SLT:     result = {31'b0, signed_lt};
            `ALU_SLTU:    result = {31'b0, unsigned_lt};
            `ALU_PASS_B:  result = operand_b;
            default:      result = 32'b0;
        endcase
    end
    
    // Status flags
    assign zero = (result == 32'b0);
    assign negative = result[31];
    assign carry = cout;
    assign overflow = (operand_a[31] == operand_b[31]) && (result[31] != operand_a[31]);

endmodule
