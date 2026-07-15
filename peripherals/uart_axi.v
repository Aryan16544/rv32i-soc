// =============================================================================
// UART with AXI-Lite Slave Interface
// =============================================================================

`include "rv32i_defines.vh"

module uart_axi #(
    parameter TX_FIFO_DEPTH = 16,
    parameter RX_FIFO_DEPTH = 16,
    parameter DEFAULT_BAUD_DIV = 16'd217
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    output wire uart_tx,
    input  wire uart_rx
);

    reg [15:0] baud_div_reg;
    reg uart_enable;

    reg [7:0] tx_data;
    reg tx_valid;
    wire tx_ready;

    wire [7:0] rx_data;
    wire rx_valid;
    reg rx_ready;

    wire tx_fifo_full = ~tx_ready;
    wire rx_fifo_empty = ~rx_valid;

    uart_tx #(
        .FIFO_DEPTH(TX_FIFO_DEPTH)
    ) tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(baud_div_reg),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx(uart_tx)
    );

    uart_rx #(
        .FIFO_DEPTH(RX_FIFO_DEPTH)
    ) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(baud_div_reg),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),
        .rx(uart_rx)
    );

    assign s_axi_arready = 1'b1;
    assign s_axi_rresp = 2'b00;

    reg rvalid_reg;
    reg [31:0] rdata_reg;
    assign s_axi_rvalid = rvalid_reg;
    assign s_axi_rdata = rdata_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg <= 32'b0;
        end else begin
            if (s_axi_arvalid && !rvalid_reg) begin
                rvalid_reg <= 1'b1;
                case (s_axi_araddr[7:0])
                    `UART_RX_DATA:  rdata_reg <= {24'b0, rx_data};
                    `UART_STATUS:   rdata_reg <= {30'b0, tx_fifo_full, rx_fifo_empty};
                    `UART_CTRL:     rdata_reg <= {31'b0, uart_enable};
                    `UART_BAUD_DIV: rdata_reg <= {16'b0, baud_div_reg};
                    default:        rdata_reg <= 32'h00000000;
                endcase
            end else if (rvalid_reg && s_axi_rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

    reg aw_captured;
    reg w_captured;
    reg [31:0] latched_awaddr;
    reg [31:0] latched_wdata;
    reg bvalid_reg;

    assign s_axi_awready = !aw_captured && !bvalid_reg;
    assign s_axi_wready = !w_captured && !bvalid_reg;
    assign s_axi_bresp = 2'b00;
    assign s_axi_bvalid = bvalid_reg;

    wire write_trigger = (aw_captured || s_axi_awvalid) &&
                         (w_captured || s_axi_wvalid) &&
                         !bvalid_reg;

    wire [31:0] final_addr = aw_captured ? latched_awaddr : s_axi_awaddr;
    wire [31:0] final_data = w_captured ? latched_wdata : s_axi_wdata;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_div_reg <= DEFAULT_BAUD_DIV;
            uart_enable <= 1'b1;
            tx_valid <= 1'b0;
            rx_ready <= 1'b0;

            bvalid_reg <= 1'b0;
            aw_captured <= 1'b0;
            w_captured <= 1'b0;
            latched_awaddr <= 0;
            latched_wdata <= 0;
        end else begin
            tx_valid <= 1'b0;
            rx_ready <= 1'b0;

            if (s_axi_awvalid && !aw_captured && !bvalid_reg) begin
                aw_captured <= 1'b1;
                latched_awaddr <= s_axi_awaddr;
            end

            if (s_axi_wvalid && !w_captured && !bvalid_reg) begin
                w_captured <= 1'b1;
                latched_wdata <= s_axi_wdata;
            end

            if (write_trigger) begin
                case (final_addr[7:0])
                    `UART_TX_DATA: begin
                        if (!tx_fifo_full && uart_enable) begin
                            tx_data <= final_data[7:0];
                            tx_valid <= 1'b1;
                        end
                    end
                    `UART_CTRL:     uart_enable <= final_data[0];
                    `UART_BAUD_DIV: baud_div_reg <= final_data[15:0];
                endcase

                bvalid_reg <= 1'b1;
                aw_captured <= 1'b0;
                w_captured <= 1'b0;
            end

            if (bvalid_reg && s_axi_bready) begin
                bvalid_reg <= 1'b0;
            end

            if (s_axi_arvalid && !rvalid_reg &&
                s_axi_araddr[7:0] == `UART_RX_DATA &&
                !rx_fifo_empty) begin
                rx_ready <= 1'b1;
            end
        end
    end

endmodule

