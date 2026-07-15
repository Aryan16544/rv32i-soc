// =============================================================================
// Simple UART Transmitter
// =============================================================================

module uart_tx_simple (
    input wire clk,
    input wire rst_n,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx_busy,
    output reg tx
);

    localparam BAUD_DIV = 16'd868;

    reg [15:0] baud_counter;
    reg baud_tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 16'd0;
            baud_tick <= 1'b0;
        end else begin
            if (baud_counter >= BAUD_DIV - 1) begin
                baud_counter <= 16'd0;
                baud_tick <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

    localparam IDLE = 4'd0;
    localparam START_BIT = 4'd1;
    localparam DATA_BIT0 = 4'd2;
    localparam DATA_BIT1 = 4'd3;
    localparam DATA_BIT2 = 4'd4;
    localparam DATA_BIT3 = 4'd5;
    localparam DATA_BIT4 = 4'd6;
    localparam DATA_BIT5 = 4'd7;
    localparam DATA_BIT6 = 4'd8;
    localparam DATA_BIT7 = 4'd9;
    localparam STOP_BIT = 4'd10;

    reg [3:0] state;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            shift_reg <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy <= 1'b1;
                        state <= START_BIT;
                    end
                end

                START_BIT: begin
                    if (baud_tick) begin
                        tx <= 1'b0;
                        state <= DATA_BIT0;
                    end
                end

                DATA_BIT0: begin
                    if (baud_tick) begin
                        tx <= shift_reg[0];
                        state <= DATA_BIT1;
                    end
                end

                DATA_BIT1: begin
                    if (baud_tick) begin
                        tx <= shift_reg[1];
                        state <= DATA_BIT2;
                    end
                end

                DATA_BIT2: begin
                    if (baud_tick) begin
                        tx <= shift_reg[2];
                        state <= DATA_BIT3;
                    end
                end

                DATA_BIT3: begin
                    if (baud_tick) begin
                        tx <= shift_reg[3];
                        state <= DATA_BIT4;
                    end
                end

                DATA_BIT4: begin
                    if (baud_tick) begin
                        tx <= shift_reg[4];
                        state <= DATA_BIT5;
                    end
                end

                DATA_BIT5: begin
                    if (baud_tick) begin
                        tx <= shift_reg[5];
                        state <= DATA_BIT6;
                    end
                end

                DATA_BIT6: begin
                    if (baud_tick) begin
                        tx <= shift_reg[6];
                        state <= DATA_BIT7;
                    end
                end

                DATA_BIT7: begin
                    if (baud_tick) begin
                        tx <= shift_reg[7];
                        state <= STOP_BIT;
                    end
                end

                STOP_BIT: begin
                    if (baud_tick) begin
                        tx <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

