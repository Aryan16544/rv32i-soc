// =============================================================================
// RV32I System-on-Chip (SoC) - Final Redesign
// Clean Architecture with Split AXI4-Lite
// =============================================================================

`include "soc_map.vh"
`include "rv32i_defines.vh"

module rv32i_soc #(
    parameter IMEM_INIT_FILE = "program.mem"
)(
    input wire clk,
    input wire rst_n,
    
    // External IO
    output wire uart_tx,
    input  wire uart_rx,
    
    input  wire [15:0] gpio_in,
    output wire [15:0] gpio_out
);

    // =========================================================================
    // Core Signals
    // =========================================================================
    // AXI-Lite Instruction Master
    wire [31:0] m_imem_awaddr; wire m_imem_awvalid; wire m_imem_awready;
    wire [31:0] m_imem_wdata;  wire [3:0] m_imem_wstrb; wire m_imem_wvalid; wire m_imem_wready;
    wire [1:0]  m_imem_bresp;  wire m_imem_bvalid;  wire m_imem_bready;
    wire [31:0] m_imem_araddr; wire m_imem_arvalid; wire m_imem_arready;
    wire [31:0] m_imem_rdata;  wire [1:0] m_imem_rresp; wire m_imem_rvalid; wire m_imem_rready;

    // AXI-Lite Data Master
    wire [31:0] m_dmem_awaddr; wire m_dmem_awvalid; wire m_dmem_awready;
    wire [31:0] m_dmem_wdata;  wire [3:0] m_dmem_wstrb; wire m_dmem_wvalid; wire m_dmem_wready;
    wire [1:0]  m_dmem_bresp;  wire m_dmem_bvalid;  wire m_dmem_bready;
    wire [31:0] m_dmem_araddr; wire m_dmem_arvalid; wire m_dmem_arready;
    wire [31:0] m_dmem_rdata;  wire [1:0] m_dmem_rresp; wire m_dmem_rvalid; wire m_dmem_rready;

    // Core Instantiation
    rv32i_core core (
        .clk(clk), .rst_n(rst_n),
        
        // IMEM Port (Read Only - Write channels tied to 0 at interconnect)
        .m_axi_imem_araddr(m_imem_araddr), .m_axi_imem_arvalid(m_imem_arvalid), .m_axi_imem_arready(m_imem_arready),
        .m_axi_imem_rdata(m_imem_rdata),   .m_axi_imem_rvalid(m_imem_rvalid),   .m_axi_imem_rready(m_imem_rready),
        .m_axi_imem_rresp(m_imem_rresp),
        // Note: m_axi_imem_aw* and w* are not present in core.
        
        // DMEM Port
        .m_axi_dmem_awaddr(m_dmem_awaddr), .m_axi_dmem_awvalid(m_dmem_awvalid), .m_axi_dmem_awready(m_dmem_awready),
        .m_axi_dmem_wdata(m_dmem_wdata),   .m_axi_dmem_wstrb(m_dmem_wstrb),     .m_axi_dmem_wvalid(m_dmem_wvalid), .m_axi_dmem_wready(m_dmem_wready),
        .m_axi_dmem_bresp(m_dmem_bresp),   .m_axi_dmem_bvalid(m_dmem_bvalid),   .m_axi_dmem_bready(m_dmem_bready),
        .m_axi_dmem_araddr(m_dmem_araddr), .m_axi_dmem_arvalid(m_dmem_arvalid), .m_axi_dmem_arready(m_dmem_arready),
        .m_axi_dmem_rdata(m_dmem_rdata),   .m_axi_dmem_rvalid(m_dmem_rvalid),   .m_axi_dmem_rready(m_dmem_rready),
        .m_axi_dmem_rresp(m_dmem_rresp)
    );

    // Tie off IMEM Write Signals for Interconnect (Master doesn't write)
    assign m_imem_awaddr = 32'b0;
    assign m_imem_awvalid = 1'b0;
    assign m_imem_wdata = 32'b0;
    assign m_imem_wstrb = 4'b0;
    assign m_imem_wvalid = 1'b0;
    assign m_imem_bready = 1'b1; // Always ready to ignore response

    // =========================================================================
    // Slave Signals (From Interconnect to Peripherals)
    // =========================================================================
    wire [31:0] s0_aw, s0_w, s0_ar; wire s0_aw_v, s0_w_v, s0_ar_v; wire [3:0] s0_strb;
    wire [31:0] s0_r; wire [1:0] s0_b, s0_rr; wire s0_b_v, s0_r_v;
    wire s0_aw_r, s0_w_r, s0_b_r, s0_ar_r, s0_r_r;

    wire [31:0] s1_aw, s1_w, s1_ar; wire s1_aw_v, s1_w_v, s1_ar_v; wire [3:0] s1_strb;
    wire [31:0] s1_r; wire [1:0] s1_b, s1_rr; wire s1_b_v, s1_r_v;
    wire s1_aw_r, s1_w_r, s1_b_r, s1_ar_r, s1_r_r;

    wire [31:0] s2_aw, s2_w, s2_ar; wire s2_aw_v, s2_w_v, s2_ar_v; wire [3:0] s2_strb;
    wire [31:0] s2_r; wire [1:0] s2_b, s2_rr; wire s2_b_v, s2_r_v;
    wire s2_aw_r, s2_w_r, s2_b_r, s2_ar_r, s2_r_r;

    wire [31:0] s3_aw, s3_w, s3_ar; wire s3_aw_v, s3_w_v, s3_ar_v; wire [3:0] s3_strb;
    wire [31:0] s3_r; wire [1:0] s3_b, s3_rr; wire s3_b_v, s3_r_v;
    wire s3_aw_r, s3_w_r, s3_b_r, s3_ar_r, s3_r_r;

    wire [31:0] s4_aw, s4_w, s4_ar; wire s4_aw_v, s4_w_v, s4_ar_v; wire [3:0] s4_strb;
    wire [31:0] s4_r; wire [1:0] s4_b, s4_rr; wire s4_b_v, s4_r_v;
    wire s4_aw_r, s4_w_r, s4_b_r, s4_ar_r, s4_r_r;

    // Interconnect Instantiation
    soc_interconnect bus (
        .clk(clk), .rst_n(rst_n),
        
        // CPU IMEM
        .cpu_i_awaddr(m_imem_awaddr), .cpu_i_awvalid(m_imem_awvalid), .cpu_i_awready(m_imem_awready),
        .cpu_i_wdata(m_imem_wdata),   .cpu_i_wstrb(m_imem_wstrb),     .cpu_i_wvalid(m_imem_wvalid), .cpu_i_wready(m_imem_wready),
        .cpu_i_bresp(m_imem_bresp),   .cpu_i_bvalid(m_imem_bvalid),   .cpu_i_bready(m_imem_bready),
        .cpu_i_araddr(m_imem_araddr), .cpu_i_arvalid(m_imem_arvalid), .cpu_i_arready(m_imem_arready),
        .cpu_i_rdata(m_imem_rdata),   .cpu_i_rresp(m_imem_rresp),     .cpu_i_rvalid(m_imem_rvalid), .cpu_i_rready(m_imem_rready),

        // CPU DMEM
        .cpu_d_awaddr(m_dmem_awaddr), .cpu_d_awvalid(m_dmem_awvalid), .cpu_d_awready(m_dmem_awready),
        .cpu_d_wdata(m_dmem_wdata),   .cpu_d_wstrb(m_dmem_wstrb),     .cpu_d_wvalid(m_dmem_wvalid), .cpu_d_wready(m_dmem_wready),
        .cpu_d_bresp(m_dmem_bresp),   .cpu_d_bvalid(m_dmem_bvalid),   .cpu_d_bready(m_dmem_bready),
        .cpu_d_araddr(m_dmem_araddr), .cpu_d_arvalid(m_dmem_arvalid), .cpu_d_arready(m_dmem_arready),
        .cpu_d_rdata(m_dmem_rdata),   .cpu_d_rresp(m_dmem_rresp),     .cpu_d_rvalid(m_dmem_rvalid), .cpu_d_rready(m_dmem_rready),

        // Slaves
        .slv0_awaddr(s0_aw), .slv0_awvalid(s0_aw_v), .slv0_awready(s0_aw_r), .slv0_wdata(s0_w), .slv0_wstrb(s0_strb), .slv0_wvalid(s0_w_v), .slv0_wready(s0_w_r), .slv0_bresp(s0_b), .slv0_bvalid(s0_b_v), .slv0_bready(s0_b_r), .slv0_araddr(s0_ar), .slv0_arvalid(s0_ar_v), .slv0_arready(s0_ar_r), .slv0_rdata(s0_r), .slv0_rresp(s0_rr), .slv0_rvalid(s0_r_v), .slv0_rready(s0_r_r),
        .slv1_awaddr(s1_aw), .slv1_awvalid(s1_aw_v), .slv1_awready(s1_aw_r), .slv1_wdata(s1_w), .slv1_wstrb(s1_strb), .slv1_wvalid(s1_w_v), .slv1_wready(s1_w_r), .slv1_bresp(s1_b), .slv1_bvalid(s1_b_v), .slv1_bready(s1_b_r), .slv1_araddr(s1_ar), .slv1_arvalid(s1_ar_v), .slv1_arready(s1_ar_r), .slv1_rdata(s1_r), .slv1_rresp(s1_rr), .slv1_rvalid(s1_r_v), .slv1_rready(s1_r_r),
        .slv2_awaddr(s2_aw), .slv2_awvalid(s2_aw_v), .slv2_awready(s2_aw_r), .slv2_wdata(s2_w), .slv2_wstrb(s2_strb), .slv2_wvalid(s2_w_v), .slv2_wready(s2_w_r), .slv2_bresp(s2_b), .slv2_bvalid(s2_b_v), .slv2_bready(s2_b_r), .slv2_araddr(s2_ar), .slv2_arvalid(s2_ar_v), .slv2_arready(s2_ar_r), .slv2_rdata(s2_r), .slv2_rresp(s2_rr), .slv2_rvalid(s2_r_v), .slv2_rready(s2_r_r),
        .slv3_awaddr(s3_aw), .slv3_awvalid(s3_aw_v), .slv3_awready(s3_aw_r), .slv3_wdata(s3_w), .slv3_wstrb(s3_strb), .slv3_wvalid(s3_w_v), .slv3_wready(s3_w_r), .slv3_bresp(s3_b), .slv3_bvalid(s3_b_v), .slv3_bready(s3_b_r), .slv3_araddr(s3_ar), .slv3_arvalid(s3_ar_v), .slv3_arready(s3_ar_r), .slv3_rdata(s3_r), .slv3_rresp(s3_rr), .slv3_rvalid(s3_r_v), .slv3_rready(s3_r_r),
        .slv4_awaddr(s4_aw), .slv4_awvalid(s4_aw_v), .slv4_awready(s4_aw_r), .slv4_wdata(s4_w), .slv4_wstrb(s4_strb), .slv4_wvalid(s4_w_v), .slv4_wready(s4_w_r), .slv4_bresp(s4_b), .slv4_bvalid(s4_b_v), .slv4_bready(s4_b_r), .slv4_araddr(s4_ar), .slv4_arvalid(s4_ar_v), .slv4_arready(s4_ar_r), .slv4_rdata(s4_r), .slv4_rresp(s4_rr), .slv4_rvalid(s4_r_v), .slv4_rready(s4_r_r)
    );
    
    // Slave 0: Boot ROM / IMEM BRAM
    soc_bram_imem #(
        .MEM_FILE(IMEM_INIT_FILE)
    ) imem (
        .clk(clk), .rst_n(rst_n),
        .s_awaddr(s0_aw), .s_awvalid(s0_aw_v), .s_awready(s0_aw_r), .s_wdata(s0_w), .s_wstrb(s0_strb), .s_wvalid(s0_w_v), .s_wready(s0_w_r), .s_bresp(s0_b), .s_bvalid(s0_b_v), .s_bready(s0_b_r),
        .s_araddr(s0_ar), .s_arvalid(s0_ar_v), .s_arready(s0_ar_r), .s_rdata(s0_r), .s_rresp(s0_rr), .s_rvalid(s0_r_v), .s_rready(s0_r_r)
    );

    // Slave 1: Main RAM / DMEM BRAM
    soc_bram_dmem dmem (
        .clk(clk), .rst_n(rst_n),
        .s_awaddr(s1_aw), .s_awvalid(s1_aw_v), .s_awready(s1_aw_r), .s_wdata(s1_w), .s_wstrb(s1_strb), .s_wvalid(s1_w_v), .s_wready(s1_w_r), .s_bresp(s1_b), .s_bvalid(s1_b_v), .s_bready(s1_b_r),
        .s_araddr(s1_ar), .s_arvalid(s1_ar_v), .s_arready(s1_ar_r), .s_rdata(s1_r), .s_rresp(s1_rr), .s_rvalid(s1_r_v), .s_rready(s1_r_r)
    );

    // Slave 2: GPIO (Need Adapter for AXI or modify soc_gpio to be AXI)
    // The previous soc_gpio found using simple valid/ready.
    
    wire [31:0] p_gpio_addr, p_gpio_wdata, p_gpio_rdata; wire p_gpio_wr, p_gpio_en;
    soc_axi_adapter adpt_gpio (
        .clk(clk), .rst_n(rst_n),
        // AXI
        .s_awaddr(s2_aw), .s_awvalid(s2_aw_v), .s_awready(s2_aw_r), .s_wdata(s2_w), .s_wstrb(s2_strb), .s_wvalid(s2_w_v), .s_wready(s2_w_r), .s_bresp(s2_b), .s_bvalid(s2_b_v), .s_bready(s2_b_r),
        .s_araddr(s2_ar), .s_arvalid(s2_ar_v), .s_arready(s2_ar_r), .s_rdata(s2_r), .s_rresp(s2_rr), .s_rvalid(s2_r_v), .s_rready(s2_r_r),
        // Simple
        .o_en(p_gpio_en), .o_addr(p_gpio_addr), .o_write(p_gpio_wr), .o_wdata(p_gpio_wdata), .i_rdata(p_gpio_rdata), .i_ready(1'b1) // GPIO always ready
    );
    soc_gpio gpio (.clk(clk), .rst_n(rst_n), .en(p_gpio_en), .addr(p_gpio_addr), .write(p_gpio_wr), .wdata(p_gpio_wdata), .rdata(p_gpio_rdata), .ready(), .valid(), .gpio_in(gpio_in), .gpio_out(gpio_out));

    // Slave 3: UART (Use Native AXI)
    uart_axi uart (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awaddr(s3_aw), .s_axi_awvalid(s3_aw_v), .s_axi_awready(s3_aw_r),
        .s_axi_wdata(s3_w), .s_axi_wstrb(s3_strb), .s_axi_wvalid(s3_w_v), .s_axi_wready(s3_w_r),
        .s_axi_bresp(s3_b), .s_axi_bvalid(s3_b_v), .s_axi_bready(s3_b_r),
        .s_axi_araddr(s3_ar), .s_axi_arvalid(s3_ar_v), .s_axi_arready(s3_ar_r),
        .s_axi_rdata(s3_r), .s_axi_rresp(s3_rr), .s_axi_rvalid(s3_r_v), .s_axi_rready(s3_r_r),
        .uart_tx(uart_tx), .uart_rx(uart_rx)
    );

    // Slave 4: Timer
    wire [31:0] p_tmr_addr, p_tmr_wdata, p_tmr_rdata; wire p_tmr_wr, p_tmr_en; wire p_tmr_rdy;
    soc_axi_adapter adpt_tmr (
        .clk(clk), .rst_n(rst_n),
        .s_awaddr(s4_aw), .s_awvalid(s4_aw_v), .s_awready(s4_aw_r), .s_wdata(s4_w), .s_wstrb(s4_strb), .s_wvalid(s4_w_v), .s_wready(s4_w_r), .s_bresp(s4_b), .s_bvalid(s4_b_v), .s_bready(s4_b_r),
        .s_araddr(s4_ar), .s_arvalid(s4_ar_v), .s_arready(s4_ar_r), .s_rdata(s4_r), .s_rresp(s4_rr), .s_rvalid(s4_r_v), .s_rready(s4_r_r),
        .o_en(p_tmr_en), .o_addr(p_tmr_addr), .o_write(p_tmr_wr), .o_wdata(p_tmr_wdata), .i_rdata(p_tmr_rdata), .i_ready(p_tmr_rdy)
    );
    soc_timer tmr (.clk(clk), .rst_n(rst_n), .en(p_tmr_en), .addr(p_tmr_addr), .write(p_tmr_wr), .wdata(p_tmr_wdata), .rdata(p_tmr_rdata), .ready(p_tmr_rdy), .valid());

endmodule
