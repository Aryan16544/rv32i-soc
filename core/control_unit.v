// =============================================================================
// Control Unit - Instruction Decoder
// Industry-Level Control Signal Generation for RV32I
// =============================================================================

`include "rv32i_defines.vh"

module control_unit (
    input wire [31:0] instruction,
    
    // Control signals
    output reg [3:0] alu_op,
    output reg alu_src_a,        // 0: rs1, 1: PC
    output reg alu_src_b,        // 0: rs2, 1: imm
    output reg mem_read,
    output reg mem_write,
    output reg [1:0] mem_size,   // 00: byte, 01: half, 10: word
    output reg mem_unsigned,
    output reg reg_write,
    output reg [1:0] wb_sel,     // 00: alu, 01: mem, 10: pc+4
    output reg branch,
    output reg jump,
    output reg jalr,
    output reg [2:0] branch_type,
    
    // Instruction fields
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire [6:0] funct7,
    output wire [4:0] rs1,
    output wire [4:0] rs2,
    output wire [4:0] rd,
    output reg [31:0] imm
);

    // Extract instruction fields
    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];
    
    // Immediate generation
    always @(*) begin
        case (opcode)
            `OPCODE_LUI, `OPCODE_AUIPC: begin
                // U-type: imm[31:12]
                imm = {instruction[31:12], 12'b0};
            end
            `OPCODE_JAL: begin
                // J-type: imm[20|10:1|11|19:12]
                imm = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end
            `OPCODE_BRANCH: begin
                // B-type: imm[12|10:5|4:1|11]
                imm = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end
            `OPCODE_LOAD, `OPCODE_JALR, `OPCODE_OP_IMM: begin
                // I-type: imm[11:0]
                imm = {{20{instruction[31]}}, instruction[31:20]};
            end
            `OPCODE_STORE: begin
                // S-type: imm[11:5|4:0]
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            default: imm = 32'b0;
        endcase
    end
    
    // Main control logic
    always @(*) begin
        // Default values
        alu_op = `ALU_ADD;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_size = `MEM_SIZE_WORD;
        mem_unsigned = 1'b0;
        reg_write = 1'b0;
        wb_sel = 2'b00;
        branch = 1'b0;
        jump = 1'b0;
        jalr = 1'b0;
        branch_type = funct3;
        
        case (opcode)
            `OPCODE_LUI: begin
                alu_op = `ALU_PASS_B;
                alu_src_b = 1'b1;
                reg_write = 1'b1;
                wb_sel = 2'b00;
            end
            
            `OPCODE_AUIPC: begin
                alu_op = `ALU_ADD;
                alu_src_a = 1'b1;  // PC
                alu_src_b = 1'b1;  // imm
                reg_write = 1'b1;
                wb_sel = 2'b00;
            end
            
            `OPCODE_JAL: begin
                jump = 1'b1;
                reg_write = 1'b1;
                wb_sel = 2'b10;  // PC+4
            end
            
            `OPCODE_JALR: begin
                jalr = 1'b1;
                reg_write = 1'b1;
                wb_sel = 2'b10;  // PC+4
            end
            
            `OPCODE_BRANCH: begin
                branch = 1'b1;
                branch_type = funct3;
            end
            
            `OPCODE_LOAD: begin
                alu_op = `ALU_ADD;
                alu_src_b = 1'b1;  // imm
                mem_read = 1'b1;
                reg_write = 1'b1;
                wb_sel = 2'b01;  // mem
                
                case (funct3)
                    `FUNCT3_LB:  begin mem_size = `MEM_SIZE_BYTE; mem_unsigned = 1'b0; end
                    `FUNCT3_LH:  begin mem_size = `MEM_SIZE_HALF; mem_unsigned = 1'b0; end
                    `FUNCT3_LW:  begin mem_size = `MEM_SIZE_WORD; mem_unsigned = 1'b0; end
                    `FUNCT3_LBU: begin mem_size = `MEM_SIZE_BYTE; mem_unsigned = 1'b1; end
                    `FUNCT3_LHU: begin mem_size = `MEM_SIZE_HALF; mem_unsigned = 1'b1; end
                    default: begin mem_size = `MEM_SIZE_WORD; mem_unsigned = 1'b0; end
                endcase
            end
            
            `OPCODE_STORE: begin
                alu_op = `ALU_ADD;
                alu_src_b = 1'b1;  // imm
                mem_write = 1'b1;
                
                case (funct3)
                    `FUNCT3_SB: mem_size = `MEM_SIZE_BYTE;
                    `FUNCT3_SH: mem_size = `MEM_SIZE_HALF;
                    `FUNCT3_SW: mem_size = `MEM_SIZE_WORD;
                    default: mem_size = `MEM_SIZE_WORD;
                endcase
            end
            
            `OPCODE_OP_IMM: begin
                alu_src_b = 1'b1;  // imm
                reg_write = 1'b1;
                wb_sel = 2'b00;  // alu
                
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_op = `ALU_ADD;
                    `FUNCT3_SLL:     alu_op = `ALU_SLL;
                    `FUNCT3_SLT:     alu_op = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_op = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_op = `ALU_XOR;
                    `FUNCT3_SRL_SRA: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                    `FUNCT3_OR:      alu_op = `ALU_OR;
                    `FUNCT3_AND:     alu_op = `ALU_AND;
                    default:         alu_op = `ALU_ADD;
                endcase
            end
            
            `OPCODE_OP: begin
                reg_write = 1'b1;
                wb_sel = 2'b00;  // alu
                
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_op = (funct7[5]) ? `ALU_SUB : `ALU_ADD;
                    `FUNCT3_SLL:     alu_op = `ALU_SLL;
                    `FUNCT3_SLT:     alu_op = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_op = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_op = `ALU_XOR;
                    `FUNCT3_SRL_SRA: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                    `FUNCT3_OR:      alu_op = `ALU_OR;
                    `FUNCT3_AND:     alu_op = `ALU_AND;
                    default:         alu_op = `ALU_ADD;
                endcase
            end
            
            default: begin
                // Illegal instruction - treat as NOP
                // All control signals already set to defaults above
            end
        endcase
    end

endmodule
