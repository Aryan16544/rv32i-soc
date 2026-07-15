// =============================================================================
// FPGA Top Level (Urbana) - PRODUCTION
// =============================================================================

module fpga_top (
    input wire CLK100MHZ,
    input wire CPU_RESETN,
    input wire UART_TXD_IN,
    output wire UART_RXD_OUT,
    
    // Functionality
    input wire [15:1] SW,
    output wire [15:0] LED
);

    // -------------------------------------------------------------------------
    // 1. Clock Generation (Reverted to Logic Divider for Stability)
    // -------------------------------------------------------------------------
    // The MMCM upgrade caused issues. Restoring original 'div' logic.
    
    // Original Logic Divider
    reg [25:0] hb_cnt;
    always @(posedge CLK100MHZ) hb_cnt <= hb_cnt + 1;
    
    // Clock Extraction: standard div[1] = 25MHz from 100MHz (div[0]=50MHz, div[1]=25MHz)
    wire cpu_clk_raw = hb_cnt[1]; // 25MHz
    
    // Global Buffer for skew control (Best Practice even for logic clocks)
    BUFG clk_bufg (.I(cpu_clk_raw), .O(cpu_clk));
    
    wire clk_locked = 1'b1; // Always locked with logic divider
    
    // Reset Synchronization (Still Good Practice)
    reg [1:0] rst_sync;
    always @(posedge cpu_clk) rst_sync <= {rst_sync[0], CPU_RESETN}; // Active Low Button -> Active Low Reset
    
    // If CPU_RESETN is active LOW (0 when pressed, 1 when released):
    // Released (1) -> rst_sync=1 -> cpu_rst_n=1 (Run)
    // Pressed (0)  -> rst_sync=0 -> cpu_rst_n=0 (Reset)
    
    assign cpu_rst_n = rst_sync[1];

/*
    // MMCM Block (Commented Out)
    wire mmcm_clk_out;
    wire mmcm_feedback;
    
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(8.0),
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(10.0),
        .CLKOUT0_DIVIDE_F(32.0),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) mmcm_inst (
        .CLKOUT0(mmcm_clk_out),
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(mmcm_feedback),
        .CLKFBOUTB(),
        .LOCKED(clk_locked),
        .CLKIN1(CLK100MHZ),
        .PWRDWN(1'b0),
        .RST(!CPU_RESETN),
        .CLKFBIN(mmcm_feedback)
    );

    BUFG clk_bufg (.I(mmcm_clk_out), .O(cpu_clk));
    
    // Synchronized Reset Release
    reg [2:0] rst_sync;
    always @(posedge cpu_clk or negedge clk_locked) begin
        if (!clk_locked) rst_sync <= 3'd0;
        else rst_sync <= {rst_sync[1:0], CPU_RESETN};
    end
    assign cpu_rst_n = rst_sync[2];
*/

    // -------------------------------------------------------------------------
    // 2. Input Synchronization (CDC)
    // -------------------------------------------------------------------------
    // UART RX Synchronizer
    // Initialize to '1' to prevent false START bit on power up!
    reg [1:0] uart_rx_sync = 2'b11; 
    always @(posedge cpu_clk) uart_rx_sync <= {uart_rx_sync[0], UART_TXD_IN};
    wire uart_rx_synced = uart_rx_sync[1]; // Use this stable signal

    // GPIO Switches Synchronizer
    // Using simple 2-stage shift register for all 15 switches at once
    reg [15:1] sw_sync_0;
    reg [15:1] sw_sync_1;
    
    always @(posedge cpu_clk) begin
        sw_sync_0 <= SW[15:1];
        sw_sync_1 <= sw_sync_0;
    end
    
    wire [15:1] sw_synced = sw_sync_1;

    // -------------------------------------------------------------------------
    // 3. SoC Instantiation
    // -------------------------------------------------------------------------
    wire [15:0] gpio_out_wire;
    
    rv32i_soc soc (
        .clk(cpu_clk),
        .rst_n(cpu_rst_n),
        .uart_tx(UART_RXD_OUT),
        .uart_rx(uart_rx_synced),     // Use synchronized signal
        .gpio_in({sw_synced, 1'b0}),  // Use synchronized switches (SW[0] is 0)
        .gpio_out(gpio_out_wire)
    );
    
    // -------------------------------------------------------------------------
    // 4. IO Assignments
    // -------------------------------------------------------------------------
    assign LED[15] = hb_cnt[25];        // Heartbeat (CLK100MHZ Alive)
    // Debug: Check if MMCM is locked and if Reset is released
    assign LED[14] = clk_locked;        // Should be ON
    assign LED[13] = cpu_rst_n;         // Should be ON (Released)
    
    // Pass through GPIO output to LEDs [12:0]
    assign LED[12:0] = gpio_out_wire[12:0];

endmodule
