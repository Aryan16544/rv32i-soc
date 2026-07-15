// =============================================================================
// SoC BRAM Data Memory
// AXI4-Lite Slave Wrapper around inferred Block RAM
// =============================================================================
`include "soc_map.vh"

module soc_bram_dmem (
    input wire clk,
    input wire rst_n,

    // AXI4-Lite Slave Interface
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output wire        s_wready,
    output wire [1:0]  s_bresp,
    output wire        s_bvalid,
    input  wire        s_bready,

    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output wire        s_arready,
    output reg  [31:0] s_rdata,
    output wire [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready
);

    parameter MEM_SIZE = `MAIN_RAM_SIZE; // 64KB

    // BRAM Implementation
    // -------------------------------------------------------------------------
    localparam WORDS = MEM_SIZE / 4;
    
    (* ram_style = "block" *) 
    reg [31:0] ram [0:WORDS-1];
    
    // AXI State Logic
    // Same as IMEM but separate file for clarity and potential diff configs
    reg aw_done, w_done, b_sent;
    
    assign s_awready = !aw_done;
    assign s_wready  = !w_done;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_done <= 0;
            w_done  <= 0;
            b_sent  <= 0;
        end else begin
            if (s_awvalid && s_awready) aw_done <= 1;
            if (s_wvalid && s_wready)   w_done  <= 1;
            if (aw_done && w_done && !b_sent) b_sent <= 1;
            if (s_bvalid && s_bready) begin
                aw_done <= 0;
                w_done  <= 0;
                b_sent  <= 0;
            end
        end
    end
    
    assign s_bvalid = aw_done && w_done && b_sent;
    assign s_bresp  = 2'b00;

    // Read Channel
    assign s_arready = !s_rvalid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_rvalid <= 0;
        end else begin
            if (s_arvalid && s_arready) begin
                s_rvalid <= 1;
            end else if (s_rvalid && s_rready) begin
                s_rvalid <= 0;
            end
        end
    end
    
    assign s_rresp = 2'b00;

    // BRAM Access
    // Use Write Address from latch or AW channel if valid?
    // We only write when aw_done and w_done are true (or about to be).
    
    // Note: To match valid timing, we need to pick the address carefully.
    // Write: s_awaddr is valid when s_awvalid=1. We latch handling internally.
    // Logic:
    // If s_awvalid, use s_awaddr.
    // If s_arvalid, use s_araddr.
    
    wire [31:0] addr_in   = s_arvalid ? s_araddr : s_awaddr;
    wire [31:0] word_addr = (addr_in & (MEM_SIZE-1)) >> 2;
    wire        we        = (s_wvalid && s_wready); // Write on the valid/ready handshake of W channel?
    // Wait, simple slave: Write when both AW and W phases are done?
    // Standard: WVALID & WREADY constitutes data transfer.
    // We need usage of AWADDR.
    // Let's rely on our State machine. "b_sent" phase is too late?
    // Write when (aw_done && s_wvalid && s_wready) OR (w_done && s_awvalid && s_awready)...
    // Simplest: Write when both valid.
    
    wire write_enable = (s_awvalid || aw_done) && (s_wvalid || w_done) && !b_sent && !s_bvalid;
    // We need to capture address if AW came earlier.
    reg [31:0] latched_awaddr;
    always @(posedge clk) if (s_awvalid && s_awready) latched_awaddr <= s_awaddr;
    
    wire [31:0] w_tgt_addr = aw_done ? latched_awaddr : s_awaddr;
    wire [31:0] final_w_addr = (w_tgt_addr & (MEM_SIZE-1)) >> 2;
    
    always @(posedge clk) begin
        if (write_enable) begin
             // Actually, this logic is tricky if state machine isn't perfectly aligned with BRAM cycle.
             // Let's use simpler "write on w_valid/ready" but assume valid address is present.
             // If we use registered address, it's fine.
             if (s_wvalid && s_wready) begin // W-Phase
                 // Address must be ready. If AW happened, it's in latched_awaddr.
                 // If AW happens now, it's in s_awaddr.
                 // This block assumes we can write.
                 if (s_wstrb[0]) ram[final_w_addr][7:0]   <= s_wdata[7:0];
                 if (s_wstrb[1]) ram[final_w_addr][15:8]  <= s_wdata[15:8];
                 if (s_wstrb[2]) ram[final_w_addr][23:16] <= s_wdata[23:16];
                 if (s_wstrb[3]) ram[final_w_addr][31:24] <= s_wdata[31:24];
             end
        end
        // Read Port
        s_rdata <= ram[word_addr]; 
    end

endmodule
