// =============================================================================
// Generic Synchronous FIFO
// =============================================================================

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst_n,

    // Write interface
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire full,

    // Read interface
    input wire rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire empty,

    // Status
    output wire [$clog2(DEPTH):0] count
);

    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;

    wire [$clog2(DEPTH)-1:0] wr_addr = wr_ptr[$clog2(DEPTH)-1:0];
    wire [$clog2(DEPTH)-1:0] rd_addr = rd_ptr[$clog2(DEPTH)-1:0];

    assign full = (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]) &&
                  (wr_addr == rd_addr);
    assign empty = (wr_ptr == rd_ptr);
    assign count = wr_ptr - rd_ptr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {($clog2(DEPTH)+1){1'b0}};
        end else if (wr_en && !full) begin
            memory[wr_addr] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= {($clog2(DEPTH)+1){1'b0}};
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    assign rd_data = memory[rd_addr];

endmodule

