// =============================================================================
// RV32I Core - Top Level Integration
// Industry-Level 5-Stage Pipelined Processor
// =============================================================================

`include "rv32i_defines.vh"

module rv32i_core (
    input wire clk,
    input wire rst_n,
    
    // AXI-Lite Master Interface for Instruction Memory
    output wire [31:0] m_axi_imem_araddr,
    output wire m_axi_imem_arvalid,
    input wire m_axi_imem_arready,
    input wire [31:0] m_axi_imem_rdata,
    input wire [1:0] m_axi_imem_rresp,
    input wire m_axi_imem_rvalid,
    output wire m_axi_imem_rready,
    
    // AXI-Lite Master Interface for Data Memory
    output wire [31:0] m_axi_dmem_awaddr,
    output wire m_axi_dmem_awvalid,
    input wire m_axi_dmem_awready,
    output wire [31:0] m_axi_dmem_wdata,
    output wire [3:0] m_axi_dmem_wstrb,
    output wire m_axi_dmem_wvalid,
    input wire m_axi_dmem_wready,
    input wire [1:0] m_axi_dmem_bresp,
    input wire m_axi_dmem_bvalid,
    output wire m_axi_dmem_bready,
    output wire [31:0] m_axi_dmem_araddr,
    output wire m_axi_dmem_arvalid,
    input wire m_axi_dmem_arready,
    input wire [31:0] m_axi_dmem_rdata,
    input wire [1:0] m_axi_dmem_rresp,
    input wire m_axi_dmem_rvalid,
    output wire m_axi_dmem_rready
);

    // -------------------------------------------------------------------------
    // Inter-stage Pipeline Signals
    // -------------------------------------------------------------------------
    
    // IF/ID
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;
    wire if_id_valid;
    
    // ID/EX
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm;
    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;
    wire [4:0] id_ex_rd;
    wire [3:0] id_ex_alu_op;
    wire id_ex_alu_src_a;
    wire id_ex_alu_src_b;
    wire id_ex_mem_read;
    wire id_ex_mem_write;
    wire [1:0] id_ex_mem_size;
    wire id_ex_mem_unsigned;
    wire id_ex_reg_write;
    wire [1:0] id_ex_wb_sel;
    wire id_ex_branch;
    wire id_ex_jump;
    wire id_ex_jalr;
    wire [2:0] id_ex_branch_type;
    wire id_ex_valid;
    
    // EX/MEM
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_rs2_data;
    wire [31:0] ex_mem_pc_plus_4;
    wire [4:0] ex_mem_rd;
    wire ex_mem_mem_read;
    wire ex_mem_mem_write;
    wire [1:0] ex_mem_mem_size;
    wire ex_mem_mem_unsigned;
    wire ex_mem_reg_write;
    wire [1:0] ex_mem_wb_sel;
    wire ex_mem_valid;
    wire [31:0] mem_result;
    
    // MEM/WB
    wire [31:0] mem_wb_result;
    wire [31:0] mem_wb_pc_plus_4;
    wire [4:0] mem_wb_rd;
    wire mem_wb_reg_write;
    wire [1:0] mem_wb_wb_sel;
    wire mem_wb_valid;
    
    // -------------------------------------------------------------------------
    // Control Signals
    // -------------------------------------------------------------------------
    
    // Hazard control
    wire stall_if;
    wire stall_id;
    wire stall_ex;
    wire flush_id;
    wire flush_ex;
    wire [1:0] forward_a;
    wire [1:0] forward_b;
    
    // Branch control
    wire branch_taken;
    wire [31:0] branch_target;
    
    // Memory stall
    wire mem_stall;
    
    // Writeback
    wire [31:0] wb_data;
    wire [4:0] wb_rd;
    wire wb_reg_write;
    
    // -------------------------------------------------------------------------
    // Instruction Memory Interface Signals
    // -------------------------------------------------------------------------
    wire [31:0] imem_addr;
    wire imem_valid;
    wire [31:0] imem_rdata;
    wire imem_ready;
    
    // Simple AXI-Lite read-only interface for instruction memory
    assign m_axi_imem_araddr = imem_addr;
    assign m_axi_imem_arvalid = imem_valid;
    assign imem_rdata = m_axi_imem_rdata;
    assign imem_ready = m_axi_imem_rvalid;
    assign m_axi_imem_rready = 1'b1;
    
    // -------------------------------------------------------------------------
    // Stage Instantiations
    // -------------------------------------------------------------------------
    
    // Fetch Stage
    fetch_stage fetch (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_if | mem_stall),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .imem_addr(imem_addr),
        .imem_valid(imem_valid),
        .imem_rdata(imem_rdata),
        .imem_ready(imem_ready),
        .if_id_pc(if_id_pc),
        .if_id_instruction(if_id_instruction),
        .if_id_valid(if_id_valid)
    );
    
    // Decode Stage
    decode_stage decode (
        .clk(clk),
        .rst_n(rst_n),
        .if_id_pc(if_id_pc),
        .if_id_instruction(if_id_instruction),
        .if_id_valid(if_id_valid),
        .stall(stall_id | mem_stall),
        .flush(flush_ex),
        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_data(wb_data),
        .id_ex_pc(id_ex_pc),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm(id_ex_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_alu_op(id_ex_alu_op),
        .id_ex_alu_src_a(id_ex_alu_src_a),
        .id_ex_alu_src_b(id_ex_alu_src_b),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_size(id_ex_mem_size),
        .id_ex_mem_unsigned(id_ex_mem_unsigned),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_wb_sel(id_ex_wb_sel),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_jalr(id_ex_jalr),
        .id_ex_branch_type(id_ex_branch_type),
        .id_ex_valid(id_ex_valid)
    );
    
    // Execute Stage
    execute_stage execute (
        .clk(clk),
        .rst_n(rst_n),
        
        .stall(stall_ex),
        
        .id_ex_pc(id_ex_pc),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm(id_ex_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_alu_op(id_ex_alu_op),
        .id_ex_alu_src_a(id_ex_alu_src_a),
        .id_ex_alu_src_b(id_ex_alu_src_b),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_size(id_ex_mem_size),
        .id_ex_mem_unsigned(id_ex_mem_unsigned),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_wb_sel(id_ex_wb_sel),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_jalr(id_ex_jalr),
        .id_ex_branch_type(id_ex_branch_type),
        .id_ex_valid(id_ex_valid),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .mem_forward_data(mem_result),
        .wb_forward_data(wb_data),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_pc_plus_4(ex_mem_pc_plus_4),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_mem_size(ex_mem_mem_size),
        .ex_mem_mem_unsigned(ex_mem_mem_unsigned),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_wb_sel(ex_mem_wb_sel),
        .ex_mem_valid(ex_mem_valid)
    );
    
    // Memory Stage
    memory_stage memory (
        .clk(clk),
        .rst_n(rst_n),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_pc_plus_4(ex_mem_pc_plus_4),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_mem_size(ex_mem_mem_size),
        .ex_mem_mem_unsigned(ex_mem_mem_unsigned),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_wb_sel(ex_mem_wb_sel),
        .ex_mem_valid(ex_mem_valid),
        .m_axi_awaddr(m_axi_dmem_awaddr),
        .m_axi_awvalid(m_axi_dmem_awvalid),
        .m_axi_awready(m_axi_dmem_awready),
        .m_axi_wdata(m_axi_dmem_wdata),
        .m_axi_wstrb(m_axi_dmem_wstrb),
        .m_axi_wvalid(m_axi_dmem_wvalid),
        .m_axi_wready(m_axi_dmem_wready),
        .m_axi_bresp(m_axi_dmem_bresp),
        .m_axi_bvalid(m_axi_dmem_bvalid),
        .m_axi_bready(m_axi_dmem_bready),
        .m_axi_araddr(m_axi_dmem_araddr),
        .m_axi_arvalid(m_axi_dmem_arvalid),
        .m_axi_arready(m_axi_dmem_arready),
        .m_axi_rdata(m_axi_dmem_rdata),
        .m_axi_rresp(m_axi_dmem_rresp),
        .m_axi_rvalid(m_axi_dmem_rvalid),
        .m_axi_rready(m_axi_dmem_rready),
        .mem_wb_result(mem_wb_result),
        .mem_wb_pc_plus_4(mem_wb_pc_plus_4),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_sel(mem_wb_wb_sel),
        .mem_wb_valid(mem_wb_valid),
        .mem_stall(mem_stall),
        .mem_result(mem_result)
    );
    
    // Writeback Stage
    writeback_stage writeback (
        .mem_wb_result(mem_wb_result),
        .mem_wb_pc_plus_4(mem_wb_pc_plus_4),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_sel(mem_wb_wb_sel),
        .mem_wb_valid(mem_wb_valid),
        .wb_data(wb_data),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write)
    );
    
    // Hazard Unit
    hazard_unit hazard (
        .id_rs1(if_id_instruction[19:15]),
        .id_rs2(if_id_instruction[24:20]),
        .ex_rs1(id_ex_rs1),
        .ex_rs2(id_ex_rs2),
        .ex_rd(id_ex_rd),
        .ex_reg_write(id_ex_reg_write),
        .ex_mem_read(id_ex_mem_read),
        .mem_rd(ex_mem_rd),
        .mem_reg_write(ex_mem_reg_write && ex_mem_valid),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write),
        .branch_taken(branch_taken),
        .jump(id_ex_jump),
        .mem_stall(mem_stall),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .stall_ex(stall_ex),
        .flush_id(flush_id),
        .flush_ex(flush_ex),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

endmodule
