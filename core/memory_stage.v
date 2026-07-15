// =============================================================================
// Memory (MEM) Stage - SIMPLIFIED
// Single-cycle memory access for simplified AXI peripherals
// =============================================================================

`include "rv32i_defines.vh"

module memory_stage (
    input wire clk,
    input wire rst_n,
    
    // Input from EX stage
    input wire [31:0] ex_mem_alu_result,
    input wire [31:0] ex_mem_rs2_data,
    input wire [31:0] ex_mem_pc_plus_4,
    input wire [4:0] ex_mem_rd,
    input wire ex_mem_mem_read,
    input wire ex_mem_mem_write,
    input wire [1:0] ex_mem_mem_size,
    input wire ex_mem_mem_unsigned,
    input wire ex_mem_reg_write,
    input wire [1:0] ex_mem_wb_sel,
    input wire ex_mem_valid,
    
    // AXI-Lite Master Interface
    output wire [31:0] m_axi_awaddr,
    output wire m_axi_awvalid,
    input wire m_axi_awready,
    
    output wire [31:0] m_axi_wdata,
    output wire [3:0] m_axi_wstrb,
    output wire m_axi_wvalid,
    input wire m_axi_wready,
    
    input wire [1:0] m_axi_bresp,
    input wire m_axi_bvalid,
    output wire m_axi_bready,
    
    output wire [31:0] m_axi_araddr,
    output wire m_axi_arvalid,
    input wire m_axi_arready,
    
    input wire [31:0] m_axi_rdata,
    input wire [1:0] m_axi_rresp,
    input wire m_axi_rvalid,
    output wire m_axi_rready,
    
    // Outputs to WB stage
    output reg [31:0] mem_wb_result,
    output reg [31:0] mem_wb_pc_plus_4,
    output reg [4:0] mem_wb_rd,
    output reg mem_wb_reg_write,
    output reg [1:0] mem_wb_wb_sel,
    output reg mem_wb_valid,
    
    // Stall signal
    output wire mem_stall,
    
    // Combinatorial result output (for forwarding)
    output wire [31:0] mem_result
);

    // =========================================================================
    // SIMPLIFIED SINGLE-CYCLE AXI INTERFACE
    // =========================================================================
    // With single-cycle peripherals, no FSM needed - direct connection
    
    // Write Address Channel
    assign m_axi_awaddr = ex_mem_alu_result;
    assign m_axi_awvalid = ex_mem_mem_write && ex_mem_valid;
    
    // Write Data Channel
    wire [31:0] write_data;
    wire [3:0] write_strb;
    
    // Generate write data and byte enables based on size
    assign write_data = (ex_mem_mem_size == `MEM_SIZE_BYTE) ? {4{ex_mem_rs2_data[7:0]}} :
                        (ex_mem_mem_size == `MEM_SIZE_HALF) ? {2{ex_mem_rs2_data[15:0]}} :
                        ex_mem_rs2_data;
    
    assign write_strb = (ex_mem_mem_size == `MEM_SIZE_BYTE) ? (4'b0001 << ex_mem_alu_result[1:0]) :
                        (ex_mem_mem_size == `MEM_SIZE_HALF) ? (ex_mem_alu_result[1] ? 4'b1100 : 4'b0011) :
                        4'b1111;
    
    assign m_axi_wdata = write_data;
    assign m_axi_wstrb = write_strb;
    assign m_axi_wvalid = ex_mem_mem_write && ex_mem_valid;
    
    // Write Response - always ready since peripherals respond immediately
    assign m_axi_bready = 1'b1;
    
    // Read Address Channel
    assign m_axi_araddr = ex_mem_alu_result;
    assign m_axi_arvalid = ex_mem_mem_read && ex_mem_valid;
    
    // Read Data - always ready
    assign m_axi_rready = 1'b1;
    
    // =========================================================================
    // Read Data Processing (sign/zero extension)
    // =========================================================================
    wire [31:0] load_data;
    wire [7:0] byte_data;
    wire [15:0] half_data;
    
    assign byte_data = (ex_mem_alu_result[1:0] == 2'b00) ? m_axi_rdata[7:0] :
                       (ex_mem_alu_result[1:0] == 2'b01) ? m_axi_rdata[15:8] :
                       (ex_mem_alu_result[1:0] == 2'b10) ? m_axi_rdata[23:16] :
                       m_axi_rdata[31:24];
    
    assign half_data = ex_mem_alu_result[1] ? m_axi_rdata[31:16] : m_axi_rdata[15:0];
    
    assign load_data = (ex_mem_mem_size == `MEM_SIZE_BYTE) ? 
                           (ex_mem_mem_unsigned ? {24'b0, byte_data} : {{24{byte_data[7]}}, byte_data}) :
                       (ex_mem_mem_size == `MEM_SIZE_HALF) ?
                           (ex_mem_mem_unsigned ? {16'b0, half_data} : {{16{half_data[15]}}, half_data}) :
                       m_axi_rdata;
    
    // =========================================================================
    // Stall Logic - Wait for AXI Handshake
    // =========================================================================
    assign mem_stall = (ex_mem_mem_read && ex_mem_valid && !m_axi_rvalid) ||
                       (ex_mem_mem_write && ex_mem_valid && !m_axi_bvalid);
    
    // =========================================================================
    // Pipeline Register: MEM/WB
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_result <= 32'b0;
            mem_wb_pc_plus_4 <= 32'b0;
            mem_wb_rd <= 5'b0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_wb_sel <= 2'b0;
            mem_wb_valid <= 1'b0;
        end else if (mem_stall) begin
            mem_wb_valid <= 1'b0; // Insert bubble into WB stage
        end else begin
            mem_wb_result <= ex_mem_mem_read ? load_data : ex_mem_alu_result;
            mem_wb_pc_plus_4 <= ex_mem_pc_plus_4;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_wb_sel <= ex_mem_wb_sel;
            mem_wb_valid <= ex_mem_valid;
        end
    end
    
    assign mem_result = ex_mem_mem_read ? load_data : ex_mem_alu_result;

endmodule
