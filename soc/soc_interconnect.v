// =============================================================================
// SoC Interconnect (AXI4-Lite)
// 2 Masters (CPU IMEM, CPU DMEM) -> 5 Slaves (ROM, RAM, UART, GPIO, Timer)
// =============================================================================

`include "soc_map.vh"
`include "rv32i_defines.vh"

module soc_interconnect (
    input wire clk,
    input wire rst_n,

    // =========================================================================
    // Slave Interfaces (Connected to CPU Masters)
    // =========================================================================
    
    // CPU Instruction Master (ReadOnly usually, but AXI is full duplex)
    input  wire [31:0] cpu_i_awaddr,
    input  wire        cpu_i_awvalid,
    output wire        cpu_i_awready,
    input  wire [31:0] cpu_i_wdata,
    input  wire [3:0]  cpu_i_wstrb,
    input  wire        cpu_i_wvalid,
    output wire        cpu_i_wready,
    output wire [1:0]  cpu_i_bresp,
    output wire        cpu_i_bvalid,
    input  wire        cpu_i_bready,
    input  wire [31:0] cpu_i_araddr,
    input  wire        cpu_i_arvalid,
    output wire        cpu_i_arready,
    output wire [31:0] cpu_i_rdata,
    output wire [1:0]  cpu_i_rresp,
    output wire        cpu_i_rvalid,
    input  wire        cpu_i_rready,

    // CPU Data Master
    input  wire [31:0] cpu_d_awaddr,
    input  wire        cpu_d_awvalid,
    output wire        cpu_d_awready,
    input  wire [31:0] cpu_d_wdata,
    input  wire [3:0]  cpu_d_wstrb,
    input  wire        cpu_d_wvalid,
    output wire        cpu_d_wready,
    output wire [1:0]  cpu_d_bresp,
    output wire        cpu_d_bvalid,
    input  wire        cpu_d_bready,
    input  wire [31:0] cpu_d_araddr,
    input  wire        cpu_d_arvalid,
    output wire        cpu_d_arready,
    output wire [31:0] cpu_d_rdata,
    output wire [1:0]  cpu_d_rresp,
    output wire        cpu_d_rvalid,
    input  wire        cpu_d_rready,

    // =========================================================================
    // Master Interfaces (Connected to Peripherals)
    // =========================================================================
    // Common Bus (Simplified to Shared Bus for output, or individual?)
    // To support simultaneous access, we need full crossbar.
    // To simplify: we'll use a shared bus Mux-Demux (1 active transaction system-wide or per-channel?)
    // Let's implement a simple shared address/data bus with arbitration.
    // If concurrent performance is needed, full crossbar is better. For standard FPGA SoC, this is fine.
    // Using Separate channels for Read and Write allows some concurrency.
    
    // Slave 0: Boot ROM
    output wire [31:0] slv0_awaddr, output wire slv0_awvalid, input wire slv0_awready,
    output wire [31:0] slv0_wdata,  output wire [3:0] slv0_wstrb, output wire slv0_wvalid, input wire slv0_wready,
    input  wire [1:0]  slv0_bresp,  input  wire slv0_bvalid,  output wire slv0_bready,
    output wire [31:0] slv0_araddr, output wire slv0_arvalid, input wire slv0_arready,
    input  wire [31:0] slv0_rdata,  input  wire [1:0] slv0_rresp, input wire slv0_rvalid, output wire slv0_rready,

    // Slave 1: Main RAM
    output wire [31:0] slv1_awaddr, output wire slv1_awvalid, input wire slv1_awready,
    output wire [31:0] slv1_wdata,  output wire [3:0] slv1_wstrb, output wire slv1_wvalid, input wire slv1_wready,
    input  wire [1:0]  slv1_bresp,  input  wire slv1_bvalid,  output wire slv1_bready,
    output wire [31:0] slv1_araddr, output wire slv1_arvalid, input wire slv1_arready,
    input  wire [31:0] slv1_rdata,  input  wire [1:0] slv1_rresp, input wire slv1_rvalid, output wire slv1_rready,

    // Slave 2: GPIO
    output wire [31:0] slv2_awaddr, output wire slv2_awvalid, input wire slv2_awready,
    output wire [31:0] slv2_wdata,  output wire [3:0] slv2_wstrb, output wire slv2_wvalid, input wire slv2_wready,
    input  wire [1:0]  slv2_bresp,  input  wire slv2_bvalid,  output wire slv2_bready,
    output wire [31:0] slv2_araddr, output wire slv2_arvalid, input wire slv2_arready,
    input  wire [31:0] slv2_rdata,  input  wire [1:0] slv2_rresp, input wire slv2_rvalid, output wire slv2_rready,
    
    // Slave 3: UART
    output wire [31:0] slv3_awaddr, output wire slv3_awvalid, input wire slv3_awready,
    output wire [31:0] slv3_wdata,  output wire [3:0] slv3_wstrb, output wire slv3_wvalid, input wire slv3_wready,
    input  wire [1:0]  slv3_bresp,  input  wire slv3_bvalid,  output wire slv3_bready,
    output wire [31:0] slv3_araddr, output wire slv3_arvalid, input wire slv3_arready,
    input  wire [31:0] slv3_rdata,  input  wire [1:0] slv3_rresp, input wire slv3_rvalid, output wire slv3_rready,

    // Slave 4: Timer
    output wire [31:0] slv4_awaddr, output wire slv4_awvalid, input wire slv4_awready,
    output wire [31:0] slv4_wdata,  output wire [3:0] slv4_wstrb, output wire slv4_wvalid, input wire slv4_wready,
    input  wire [1:0]  slv4_bresp,  input  wire slv4_bvalid,  output wire slv4_bready,
    output wire [31:0] slv4_araddr, output wire slv4_arvalid, input wire slv4_arready,
    input  wire [31:0] slv4_rdata,  input  wire [1:0] slv4_rresp, input wire slv4_rvalid, output wire slv4_rready
);

    // =========================================================================
    // Address Map Functions
    // =========================================================================
    function [2:0] addr_decode(input [31:0] addr);
        begin
            if      ((addr & `BOOT_ROM_MASK) == `BOOT_ROM_BASE) addr_decode = 3'd0;
            else if ((addr & `MAIN_RAM_MASK) == `MAIN_RAM_BASE) addr_decode = 3'd1;
            else if ((addr & `GPIO_MASK)     == `GPIO_BASE)     addr_decode = 3'd2;
            else if ((addr & `UART_MASK)     == `UART_BASE)     addr_decode = 3'd3;
            else if ((addr & `TIMER_MASK)    == `TIMER_BASE)    addr_decode = 3'd4;
            else                                                addr_decode = 3'd7; // Error
        end
    endfunction

    // =========================================================================
    // =========================================================================
    // Read Channel Arbiter
    // =========================================================================
    // Priority: Data Master > Instruction Master
    
    // Manual Arbitration Logic is implemented below (see 'r_lock' section).
    // We removed the simplified concurrent assignment that caused multi-driver errors.
    // Needs to know which Slave is responding to WHICH Master.
    // Simplifying assumption: Outstanding transactions = 1 per master?
    // If we use simple muxing based on current grant, we assume atomic operations.
    // AXI-Lite allows response delay. We need to remember who requested.
    
    // State machine for Read Routing?
    // To support full AXI split phase, we need to track ID or order.
    // Simple approach: Lock Arbiter until RVALID && RREADY.
    
    // State machine for Read Routing?
    // To support full AXI split phase, we need to track ID or order.
    // Simple approach: Lock Arbiter until RVALID && RREADY.
    
    // We already have r_state and logic below (manual implementation).
    // The previous 'data_arbiter' module was a placeholder.
    // We use the 'r_lock' manual logic defined below.
    
    reg r_lock;
    reg r_owner; // 0=I, 1=D
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_lock <= 0;
            r_owner <= 0;
        end else begin
            if (!r_lock) begin
                if (cpu_d_arvalid) begin
                    r_lock <= 1;
                    r_owner <= 1;
                end else if (cpu_i_arvalid) begin
                    r_lock <= 1;
                    r_owner <= 0;
                end
            end else begin
                // Unlock when transaction finishes
                // RVALID && RREADY logic from the active slave/master
                if (r_owner) begin // Data Master
                     if (cpu_d_rvalid && cpu_d_rready) r_lock <= 0;
                end else begin // Instr Master
                     if (cpu_i_rvalid && cpu_i_rready) r_lock <= 0;
                end
            end
        end
    end
    
    wire active_d = (!r_lock && cpu_d_arvalid) || (r_lock && r_owner);
    wire active_i = (!r_lock && !cpu_d_arvalid && cpu_i_arvalid) || (r_lock && !r_owner);
    
    // Address Path Mux
    wire [31:0] arb_araddr = active_d ? cpu_d_araddr : cpu_i_araddr;
    wire        arb_arvalid = active_d ? cpu_d_arvalid : (active_i ? cpu_i_arvalid : 0);
    wire [2:0]  arb_rsel = addr_decode(arb_araddr);
    
    assign slv0_araddr = arb_araddr; assign slv0_arvalid = arb_arvalid && (arb_rsel == 0) && !r_lock; // Only assert valid at start
    assign slv1_araddr = arb_araddr; assign slv1_arvalid = arb_arvalid && (arb_rsel == 1) && !r_lock;
    assign slv2_araddr = arb_araddr; assign slv2_arvalid = arb_arvalid && (arb_rsel == 2) && !r_lock;
    assign slv3_araddr = arb_araddr; assign slv3_arvalid = arb_arvalid && (arb_rsel == 3) && !r_lock;
    assign slv4_araddr = arb_araddr; assign slv4_arvalid = arb_arvalid && (arb_rsel == 4) && !r_lock;
    
    // ARREADY return (only during address phase/no lock)
    assign cpu_d_arready = active_d && !r_lock ? ((arb_rsel==0)?slv0_arready : (arb_rsel==1)?slv1_arready : (arb_rsel==2)?slv2_arready : (arb_rsel==3)?slv3_arready : (arb_rsel==4)?slv4_arready : 1'b0) : 1'b0;
    assign cpu_i_arready = active_i && !r_lock ? ((arb_rsel==0)?slv0_arready : (arb_rsel==1)?slv1_arready : (arb_rsel==2)?slv2_arready : (arb_rsel==3)?slv3_arready : (arb_rsel==4)?slv4_arready : 1'b0) : 1'b0;

    // Read Data Mux
    // We need to know which slave was selected during the address phase.
    // Latch selection?
    reg [2:0] r_sel_latched;
    always @(posedge clk) if (!r_lock && arb_arvalid) r_sel_latched <= arb_rsel;
    
    wire [31:0] mux_rdata = (r_sel_latched==0)?slv0_rdata : (r_sel_latched==1)?slv1_rdata : (r_sel_latched==2)?slv2_rdata : (r_sel_latched==3)?slv3_rdata : (r_sel_latched==4)?slv4_rdata : 32'b0;
    wire [1:0]  mux_rresp = (r_sel_latched==0)?slv0_rresp : (r_sel_latched==1)?slv1_rresp : (r_sel_latched==2)?slv2_rresp : (r_sel_latched==3)?slv3_rresp : (r_sel_latched==4)?slv4_rresp : 2'b00;
    wire        mux_rvalid= (r_sel_latched==0)?slv0_rvalid : (r_sel_latched==1)?slv1_rvalid : (r_sel_latched==2)?slv2_rvalid : (r_sel_latched==3)?slv3_rvalid : (r_sel_latched==4)?slv4_rvalid : 1'b0;
    
    assign cpu_d_rdata  = mux_rdata;
    assign cpu_d_rresp  = mux_rresp;
    assign cpu_d_rvalid = active_d && mux_rvalid; // Only send valid to owner
    
    assign cpu_i_rdata  = mux_rdata;
    assign cpu_i_rresp  = mux_rresp;
    assign cpu_i_rvalid = active_i && mux_rvalid;
    
    // RREADY broadcast to selected slave
    wire mux_rready = (active_d ? cpu_d_rready : 0) | (active_i ? cpu_i_rready : 0);
    assign slv0_rready = mux_rready && (r_sel_latched==0); 
    assign slv1_rready = mux_rready && (r_sel_latched==1);
    assign slv2_rready = mux_rready && (r_sel_latched==2);
    assign slv3_rready = mux_rready && (r_sel_latched==3);
    assign slv4_rready = mux_rready && (r_sel_latched==4);

    // =========================================================================
    // Write Channel Arbiter (Simpler, usually only Data Master writes)
    // =========================================================================
    // Check if IMEM ever writes. Usually no.
    // If IMEM doesn't write, we can hardwire I Write ports to 0.
    // Assume only CPU Data Master writes.
    
    // Address Path
    wire [31:0] w_awaddr = cpu_d_awaddr;
    wire        w_awvalid = cpu_d_awvalid;
    wire [2:0]  w_sel = addr_decode(w_awaddr);
    
    assign slv0_awaddr = w_awaddr; assign slv0_awvalid = w_awvalid && (w_sel==0);
    assign slv1_awaddr = w_awaddr; assign slv1_awvalid = w_awvalid && (w_sel==1);
    assign slv2_awaddr = w_awaddr; assign slv2_awvalid = w_awvalid && (w_sel==2);
    assign slv3_awaddr = w_awaddr; assign slv3_awvalid = w_awvalid && (w_sel==3);
    assign slv4_awaddr = w_awaddr; assign slv4_awvalid = w_awvalid && (w_sel==4);
    
    assign cpu_d_awready = (w_sel==0)?slv0_awready : (w_sel==1)?slv1_awready : (w_sel==2)?slv2_awready : (w_sel==3)?slv3_awready : (w_sel==4)?slv4_awready : 1'b0;

    // Data Path
    // WVALID should probably also be gated, but standard AXI allows W before AW. 
    // However, our slaves expect correlated functionality. Let's pass it through but it relies on AW.
    assign slv0_wdata = cpu_d_wdata; assign slv0_wstrb = cpu_d_wstrb; assign slv0_wvalid = cpu_d_wvalid && (w_sel==0);
    assign slv1_wdata = cpu_d_wdata; assign slv1_wstrb = cpu_d_wstrb; assign slv1_wvalid = cpu_d_wvalid && (w_sel==1);
    assign slv2_wdata = cpu_d_wdata; assign slv2_wstrb = cpu_d_wstrb; assign slv2_wvalid = cpu_d_wvalid && (w_sel==2);
    assign slv3_wdata = cpu_d_wdata; assign slv3_wstrb = cpu_d_wstrb; assign slv3_wvalid = cpu_d_wvalid && (w_sel==3);
    assign slv4_wdata = cpu_d_wdata; assign slv4_wstrb = cpu_d_wstrb; assign slv4_wvalid = cpu_d_wvalid && (w_sel==4);

    assign cpu_d_wready = (w_sel==0)?slv0_wready : (w_sel==1)?slv1_wready : (w_sel==2)?slv2_wready : (w_sel==3)?slv3_wready : (w_sel==4)?slv4_wready : 1'b0;

    // Write Response Path
    // Need to latch W_SEL? Yes, BVALID comes later.
    reg [2:0] w_sel_latched;
    // Simple logic: Latch when AW happens. Unlock when B happens.
    reg w_lock;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_lock <= 0;
        end else begin
            if (!w_lock && cpu_d_awvalid && cpu_d_awready) begin
                w_lock <= 1;
                w_sel_latched <= w_sel;
            end else if (w_lock && cpu_d_bvalid && cpu_d_bready) begin
                w_lock <= 0;
            end
        end
    end
    
    // We should use w_sel_latched for B-channel routing
    wire [1:0] mux_bresp = (w_lock && w_sel_latched==0)?slv0_bresp : (w_lock && w_sel_latched==1)?slv1_bresp : (w_lock && w_sel_latched==2)?slv2_bresp : (w_lock && w_sel_latched==3)?slv3_bresp : (w_lock && w_sel_latched==4)?slv4_bresp : 2'b00;
    wire       mux_bvalid= (w_lock && w_sel_latched==0)?slv0_bvalid : (w_lock && w_sel_latched==1)?slv1_bvalid : (w_lock && w_sel_latched==2)?slv2_bvalid : (w_lock && w_sel_latched==3)?slv3_bvalid : (w_lock && w_sel_latched==4)?slv4_bvalid : 1'b0;
    
    assign cpu_d_bresp  = mux_bresp;
    assign cpu_d_bvalid = mux_bvalid;

    assign slv0_bready = w_lock && (w_sel_latched==0) && cpu_d_bready;
    assign slv1_bready = w_lock && (w_sel_latched==1) && cpu_d_bready;
    assign slv2_bready = w_lock && (w_sel_latched==2) && cpu_d_bready;
    assign slv3_bready = w_lock && (w_sel_latched==3) && cpu_d_bready;
    assign slv4_bready = w_lock && (w_sel_latched==4) && cpu_d_bready;

    // Tie off Instruction Write Inputs (IMEM is read-only)
    assign cpu_i_awready = 1'b1; // Accept and ignore? Or Error? High to avoid hang if tried.
    assign cpu_i_wready  = 1'b1;
    assign cpu_i_bresp   = 2'b00;
    assign cpu_i_bvalid  = 1'b0; // Never return write valid

endmodule
