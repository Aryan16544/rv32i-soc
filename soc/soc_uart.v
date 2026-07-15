// =============================================================================
// SoC UART Wrapper
// Adapts the existing uart_axi to the simplified interface
// =============================================================================
`include "soc_map.vh"

module soc_uart (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [31:0] addr,
    input wire write,
    input wire [31:0] wdata,
    output wire [31:0] rdata,
    output wire valid,
    output wire ready,
    
    output wire tx,
    input wire rx
);

    // Instantiate existing uart_axi, but drive it carefully
    
    // AXI Generation
    wire [31:0] axi_awaddr = addr;
    wire        axi_awvalid = en && write;
    wire [31:0] axi_wdata = wdata;
    wire        axi_wvalid = en && write;
    wire [3:0]  axi_wstrb = 4'b0001; // Byte mode usually
    
    wire [31:0] axi_araddr = addr;
    wire        axi_arvalid = en && !write;
    
    wire        axi_awready, axi_wready, axi_arready;
    wire        axi_bvalid, axi_rvalid;
    
    assign ready = (write) ? (axi_awready && axi_wready) : (axi_arready);
    // UART AXI often gives response next cycle. We need to match.
    // The previous module logic was "relaxed".
    
    // Actually, let's use the core uart logic directly or trust the axi wrapper?
    // Let's trust the axi wrapper but ensure valid/ready handshake works.
    
    // Simple passthrough for valid:
    assign valid = (write) ? axi_bvalid : axi_rvalid;
    
    uart_axi uart_inst (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awaddr(axi_awaddr), .s_axi_awvalid(axi_awvalid), .s_axi_awready(axi_awready),
        .s_axi_wdata(axi_wdata), .s_axi_wstrb(axi_wstrb), .s_axi_wvalid(axi_wvalid), .s_axi_wready(axi_wready),
        .s_axi_bvalid(axi_bvalid), .s_axi_bready(1'b1), // Always accept response
        
        .s_axi_araddr(axi_araddr), .s_axi_arvalid(axi_arvalid), .s_axi_arready(axi_arready),
        .s_axi_rdata(rdata), .s_axi_rvalid(axi_rvalid), .s_axi_rready(1'b1),
        
        .uart_tx(tx), .uart_rx(rx)
    );

endmodule
