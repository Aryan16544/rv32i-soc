// =============================================================================
// SoC BRAM Instruction Memory
// AXI4-Lite Slave Wrapper around inferred Block RAM
// =============================================================================
`include "soc_map.vh"

module soc_bram_imem (
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

    parameter MEM_SIZE = `BOOT_ROM_SIZE; // Use definition from map
    parameter MEM_FILE = "program.mem";

    // AXI Signalling
    // -------------------------------------------------------------------------
    // Simple Slave: Ready when valid. 
    // Reads are 1-cycle latency (BRAM style).
    
    // Write Handling (IMEM is typically RO, but nice to simple support write if ever needed)
    // We ignore writes or implement them? Let's implement for flexibility (Loading via debugger).
    
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
            
            if (aw_done && w_done && !b_sent) begin
                // Write happens here
                b_sent <= 1;
            end
            
            if (s_bvalid && s_bready) begin
                aw_done <= 0;
                w_done  <= 0;
                b_sent  <= 0;
            end
        end
    end
    
    assign s_bvalid = aw_done && w_done && b_sent;
    assign s_bresp  = 2'b00; // OKAY

    // Read Handling
    // -------------------------------------------------------------------------
    assign s_arready = !s_rvalid; // Only accept address if not outputting data
    
    reg [31:0] mem_rdata;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_rvalid <= 0;
        end else begin
            if (s_arvalid && s_arready) begin
                s_rvalid <= 1;
                // Capture data from BRAM (Combinational read or synchronous? BRAM is sync read)
                // We use synchronous BRAM, so data appears next cycle. 
                // Wait. If BRAM is synchronous, we assert rvalid next cycle.
                // This logic here asserts rvalid NOW? No, next cycle.
            end else if (s_rvalid && s_rready) begin
                s_rvalid <= 0;
            end
        end
    end
    
    assign s_rresp = 2'b00; // OKAY
    // s_rdata is hooked to BRAM output

    // BRAM Implementation
    // -------------------------------------------------------------------------
    // Xilinx Single Port RAM with Byte Write
    
    localparam WORDS = MEM_SIZE / 4;
    
    // Force Vivado Update
    (* rom_style = "block" *) 
    reg [31:0] ram [0:4095];
    
    initial begin
        $readmemh(MEM_FILE, ram);
    end
    
    // Port A (Unified Read/Write)
    wire [31:0] addr_in = s_arvalid ? s_araddr : s_awaddr; // Mux address
    wire [31:0] word_addr = (addr_in & (MEM_SIZE-1)) >> 2;
    wire        we        = (aw_done && w_done && !b_sent); // Pulse write
    
    // Note: BRAM read is synchronous.
    // If we use address from s_araddr directly:
    // Cycle 0: s_arvalid=1. s_arready=1. Address available.
    // Cycle 1: BRAM outputs data. s_rvalid=1.
    // Perfect.
    
    always @(posedge clk) begin
        if (we) begin
            if (s_wstrb[0]) ram[word_addr][7:0]   <= s_wdata[7:0];
            if (s_wstrb[1]) ram[word_addr][15:8]  <= s_wdata[15:8];
            if (s_wstrb[2]) ram[word_addr][23:16] <= s_wdata[23:16];
            if (s_wstrb[3]) ram[word_addr][31:24] <= s_wdata[31:24];
        end
        s_rdata <= ram[word_addr]; // Read always happens
    end

endmodule
