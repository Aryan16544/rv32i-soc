// =============================================================================
// UART Transmitter with FIFO
// =============================================================================

module uart_tx #(
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_n,

    input wire [15:0] baud_div,

    input wire [7:0] tx_data,
    input wire tx_valid,
    output wire tx_ready,

    output reg tx
);

    wire fifo_empty;
    wire fifo_full;
    wire [7:0] fifo_data;
    reg fifo_rd_en;

    fifo #(
        .DATA_WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) tx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(tx_valid),
        .wr_data(tx_data),
        .full(fifo_full),
        .rd_en(fifo_rd_en),
        .rd_data(fifo_data),
        .empty(fifo_empty),
        .count()
    );

    assign tx_ready = ~fifo_full;

    reg [15:0] baud_counter;
    reg baud_tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 16'b0;
            baud_tick <= 1'b0;
        end else begin
            if (baud_counter >= baud_div - 1) begin
                baud_counter <= 16'b0;
                baud_tick <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

    localparam IDLE = 4'd0;
    localparam START_BIT = 4'd1;
    localparam DATA_BIT_0 = 4'd2;
    localparam DATA_BIT_1 = 4'd3;
    localparam DATA_BIT_2 = 4'd4;
    localparam DATA_BIT_3 = 4'd5;
    localparam DATA_BIT_4 = 4'd6;
    localparam DATA_BIT_5 = 4'd7;
    localparam DATA_BIT_6 = 4'd8;
    localparam DATA_BIT_7 = 4'd9;
    localparam STOP_BIT = 4'd10;

    reg [3:0] state;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx <= 1'b1;
            shift_reg <= 8'b0;
            fifo_rd_en <= 1'b0;
        end else begin
            fifo_rd_en <= 1'b0;

            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        tx <= 1'b1;
                        if (!fifo_empty) begin
                            shift_reg <= fifo_data;
                            fifo_rd_en <= 1'b1;
                            state <= START_BIT;
                        end
                    end

                    START_BIT: begin
                        tx <= 1'b0;
                        state <= DATA_BIT_0;
                    end

                    DATA_BIT_0: begin
                        tx <= shift_reg[0];
                        state <= DATA_BIT_1;
                    end

                    DATA_BIT_1: begin
                        tx <= shift_reg[1];
                        state <= DATA_BIT_2;
                    end

                    DATA_BIT_2: begin
                        tx <= shift_reg[2];
                        state <= DATA_BIT_3;
                    end

                    DATA_BIT_3: begin
                        tx <= shift_reg[3];
                        state <= DATA_BIT_4;
                    end

                    DATA_BIT_4: begin
                        tx <= shift_reg[4];
                        state <= DATA_BIT_5;
                    end

                    DATA_BIT_5: begin
                        tx <= shift_reg[5];
                        state <= DATA_BIT_6;
                    end

                    DATA_BIT_6: begin
                        tx <= shift_reg[6];
                        state <= DATA_BIT_7;
                    end

                    DATA_BIT_7: begin
                        tx <= shift_reg[7];
                        state <= STOP_BIT;
                    end

                    STOP_BIT: begin
                        tx <= 1'b1;
                        state <= IDLE;
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule

