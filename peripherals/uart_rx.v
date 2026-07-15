// =============================================================================
// UART Receiver with FIFO
// =============================================================================

module uart_rx #(
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_n,

    input wire [15:0] baud_div,

    output wire [7:0] rx_data,
    output wire rx_valid,
    input wire rx_ready,

    input wire rx
);

    wire fifo_full;
    wire fifo_empty;
    reg [7:0] fifo_wr_data;
    reg fifo_wr_en;

    fifo #(
        .DATA_WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) rx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data),
        .full(fifo_full),
        .rd_en(rx_ready),
        .rd_data(rx_data),
        .empty(fifo_empty),
        .count()
    );

    assign rx_valid = ~fifo_empty;

    reg [15:0] baud_counter;
    reg baud_tick;
    wire [15:0] oversample_div = baud_div >> 4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 16'b0;
            baud_tick <= 1'b0;
        end else begin
            if (baud_counter >= oversample_div - 1) begin
                baud_counter <= 16'b0;
                baud_tick <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

    reg [2:0] rx_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_sync <= 3'b111;
        else
            rx_sync <= {rx_sync[1:0], rx};
    end

    wire rx_stable = rx_sync[2];
    wire rx_falling = (rx_sync[2:1] == 2'b10);

    localparam IDLE = 4'd0;
    localparam START_BIT = 4'd1;
    localparam DATA_BIT = 4'd2;
    localparam STOP_BIT = 4'd3;

    reg [3:0] state;
    reg [3:0] bit_cnt;
    reg [3:0] sample_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 4'b0;
            sample_cnt <= 4'b0;
            shift_reg <= 8'b0;
            fifo_wr_en <= 1'b0;
            fifo_wr_data <= 8'b0;
        end else begin
            fifo_wr_en <= 1'b0;

            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        if (rx_falling) begin
                            state <= START_BIT;
                            sample_cnt <= 4'd0;
                        end
                    end

                    START_BIT: begin
                        if (sample_cnt == 4'd7) begin
                            if (rx_stable == 1'b0) begin
                                state <= DATA_BIT;
                                bit_cnt <= 4'd0;
                                sample_cnt <= 4'd0;
                            end else begin
                                state <= IDLE;
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end

                    DATA_BIT: begin
                        if (sample_cnt == 4'd15) begin
                            shift_reg <= {rx_stable, shift_reg[7:1]};
                            sample_cnt <= 4'd0;

                            if (bit_cnt == 4'd7) begin
                                state <= STOP_BIT;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end

                    STOP_BIT: begin
                        if (sample_cnt == 4'd15) begin
                            if (rx_stable == 1'b1 && !fifo_full) begin
                                fifo_wr_data <= shift_reg;
                                fifo_wr_en <= 1'b1;
                            end
                            state <= IDLE;
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule

