// =============================================================================
// UART Loopback Test for Urbana Board
// Receives a byte from PC and echoes it back immediately.
// =============================================================================

module fpga_uart_echo (
    input wire CLK100MHZ,      // 100MHz clock
    input wire CPU_RESETN,     // Active-low reset button (SW[0])
    input wire UART_TXD_IN,    // UART RX Input (from PC)
    output wire UART_RXD_OUT,  // UART TX Output (to PC)
    output wire [15:0] LED     // Debug LEDs
);

    // -------------------------------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------------------------------
    wire clk = CLK100MHZ;
    wire rst_n = CPU_RESETN;

    // -------------------------------------------------------------------------
    // UART Parameters
    // -------------------------------------------------------------------------
    // 100MHz / 115200 baud = 868.05
    localparam BAUD_DIV = 16'd868;

    // -------------------------------------------------------------------------
    // Internal Signals
    // -------------------------------------------------------------------------
    wire [7:0] rx_data;
    wire rx_valid;
    wire tx_ready;
    reg tx_valid;
    reg [7:0] tx_data;
    
    // -------------------------------------------------------------------------
    // UART Receiver
    // -------------------------------------------------------------------------
    uart_rx #(
        .FIFO_DEPTH(16)
    ) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(BAUD_DIV),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(1'b1), // Always ready to receive (pop from FIFO immediately)
        .rx(UART_TXD_IN)
    );

    // -------------------------------------------------------------------------
    // Loopback Logic
    // -------------------------------------------------------------------------
    // When we get a valid byte from RX, we send it to TX
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_valid <= 1'b0;
            tx_data <= 8'b0;
        end else begin
            // Default: clear tx_valid after one cycle
            tx_valid <= 1'b0;
            
            if (rx_valid && tx_ready) begin
                tx_data <= rx_data;
                tx_valid <= 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // UART Transmitter
    // -------------------------------------------------------------------------
    uart_tx #(
        .FIFO_DEPTH(16)
    ) tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(BAUD_DIV),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx(UART_RXD_OUT)
    );

    // -------------------------------------------------------------------------
    // LED Status
    // -------------------------------------------------------------------------
    assign LED[0] = rst_n;          // Access alive
    assign LED[1] = ~UART_TXD_IN;   // Flash on RX activity
    assign LED[2] = ~UART_RXD_OUT;  // Flash on TX activity
    assign LED[15:8] = rx_data;     // Display last received character
    assign LED[7:3] = 5'b0;

endmodule
