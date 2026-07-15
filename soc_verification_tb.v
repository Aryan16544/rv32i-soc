// =============================================================================
// SoC Verification Testbench (Verilog-2001)
// Simulates the Full Industry Grade SoC
// =============================================================================

`timescale 1ns/1ps

module soc_verification_tb;

    // -------------------------------------------------------------------------
    // Signal Interpretations
    // -------------------------------------------------------------------------
    reg clk;
    reg rst_n;
    
    // UART
    wire uart_tx;
    reg  uart_rx;
    
    // GPIO
    reg  [15:0] gpio_in;
    wire [15:0] gpio_out;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    rv32i_soc #(
        .IMEM_INIT_FILE("rv32i_test_program.mem")
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    // -------------------------------------------------------------------------
    // Clock Generation (100MHz equivalent for sim)
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Initialize Inputs
        rst_n = 0;
        uart_rx = 1; // Idle High
        gpio_in = 16'hDEAD; // Test Input Pattern

        // Reset Sequence
        $display("[%t] Asserting Reset...", $time);
        #100;
        @(posedge clk);
        rst_n = 1;
        $display("[%t] Reset Released. Processor Starting...", $time);

        // Wait for boot (Hardware jump 0x00 -> 0x10000000)
        #2000;
        
        // Monitor GPIO Output check
        // If program.mem writes to GPIO, we catch it here.
        $display("[%t] Checking GPIO Output...", $time);
        if (gpio_out !== 16'h0000) begin
            $display("SUCCESS: GPIO Output changed to 0x%h", gpio_out);
        end else begin
            $display("INFO: GPIO Output is 0x%h (Program might still be booting)", gpio_out);
        end

        // Run longer
        #5000;
        if (gpio_out !== 16'h0000) begin
             $display("SUCCESS (Latest): GPIO Output is 0x%h", gpio_out);
        end
        #5000;
        $finish;
    end
    
    // -------------------------------------------------------------------------
    // Monitors
    // -------------------------------------------------------------------------
    always @(gpio_out) begin
        $display("[%t] MONITOR: GPIO Output changed to 0x%h", $time, gpio_out);
    end

endmodule
