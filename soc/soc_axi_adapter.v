// =============================================================================
// SoC AXI Adapter
// Bridges AXI4-Lite Slave to Simple IP Interface (En, Addr, Write, WData, RData)
// =============================================================================
module soc_axi_adapter (
    input wire clk,
    input wire rst_n,
    
    // AXI Slave Interface
    input  wire [31:0] s_awaddr, input wire s_awvalid, output wire s_awready,
    input  wire [31:0] s_wdata,  input wire [3:0] s_wstrb, input wire s_wvalid, output wire s_wready,
    output wire [1:0]  s_bresp,  output wire s_bvalid, input wire s_bready,
    input  wire [31:0] s_araddr, input wire s_arvalid, output wire s_arready,
    output wire [31:0] s_rdata,  output wire [1:0] s_rresp, output wire s_rvalid, input wire s_rready,

    // Simple IP Interface
    output reg         o_en,
    output reg  [31:0] o_addr,
    output reg         o_write,
    output reg  [31:0] o_wdata,
    input  wire [31:0] i_rdata,
    input  wire        i_ready // Assumed 1 or wait
);

    // State Machine
    // Idle -> (Write Addr/Data) -> Trigger IP -> Wait Response -> BVALID -> Idle
    // Idle -> (Read Addr) -> Trigger IP -> Wait Response -> RVALID -> Idle
    
    // Simplification: No outstanding transactions, blocking.
    
    reg [2:0] state;
    localparam S_IDLE = 0, S_WRITE_IP = 1, S_WRITE_RESP = 2, S_READ_IP = 3, S_READ_RESP = 4;
    
    // Correct AXI Handshake Logic
    // We must accept AW and W independently.
    
    reg aw_captured, w_captured;
    reg [31:0] latched_addr;
    reg [31:0] latched_wdata;
    
    // Handshake assignments
    assign s_awready = (state == S_IDLE) && !aw_captured;
    assign s_wready  = (state == S_IDLE) && !w_captured;
    assign s_arready = (state == S_IDLE) && !aw_captured && !w_captured && !s_awvalid; // Prioritize Write?
    
    assign s_bvalid = (state == S_WRITE_RESP);
    assign s_bresp  = 2'b00;
    assign s_rvalid = (state == S_READ_RESP);
    assign s_rresp  = 2'b00;
    
    wire write_complete = (aw_captured || s_awvalid) && (w_captured || s_wvalid);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            o_en <= 0;
            o_write <= 0;
            o_addr <= 0;
            o_wdata <= 0;
            rdata_reg <= 0;
            aw_captured <= 0;
            w_captured <= 0;
        end else begin
            // Input Latching (Independent)
            if (state == S_IDLE) begin
                if (s_awvalid && !aw_captured) begin
                    aw_captured <= 1;
                    latched_addr <= s_awaddr;
                end
                if (s_wvalid && !w_captured) begin
                    w_captured <= 1;
                    latched_wdata <= s_wdata;
                end
            end
            
            case (state)
                S_IDLE: begin
                    o_en <= 0;
                    
                    // Check if we have a full Write Request
                    if (write_complete) begin
                        o_addr <= aw_captured ? latched_addr : s_awaddr;
                        o_wdata <= w_captured ? latched_wdata : s_wdata;
                        o_write <= 1;
                        o_en <= 1;
                        state <= S_WRITE_IP;
                        // Clear capture flags for next time (they are consumed state-wise)
                        // But wait, we need to ensure we don't re-trigger.
                    end 
                    // Check for Read Request (Simple AR)
                    else if (s_arvalid && !aw_captured && !w_captured) begin // Only read if no partial write
                        o_addr <= s_araddr;
                        o_write <= 0;
                        o_en <= 1;
                        state <= S_READ_IP;
                    end
                end
                
                S_WRITE_IP: begin
                    // Consume the captured inputs now that we started
                    aw_captured <= 0;
                    w_captured <= 0;
                    
                    o_en <= 0; 
                    if (i_ready) begin 
                         state <= S_WRITE_RESP;
                    end
                end
                
                S_WRITE_RESP: begin
                    if (s_bready) state <= S_IDLE;
                end
                
                S_READ_IP: begin
                    o_en <= 0;
                    if (i_ready) begin
                         rdata_reg <= i_rdata;
                         state <= S_READ_RESP;
                    end
                end
                
                S_READ_RESP: begin
                    if (s_rready) state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
