// =============================================================================
// SoC GPIO Controller
// =============================================================================
module soc_gpio (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [31:0] addr,
    input wire write,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    output reg valid,
    output wire ready,
    
    // External
    input wire [15:0] gpio_in,
    output wire [15:0] gpio_out
);

    reg [15:0] out_reg;
    reg [15:0] dir_reg;
    
    assign gpio_out = out_reg;
    assign ready = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
            out_reg <= 16'h0000;
            dir_reg <= 16'h0000;
        end else begin
            if (en) begin
                valid <= 1'b1;
                if (write) begin
                    case (addr[7:0])
                        8'h04: out_reg <= wdata[15:0];
                        8'h08: dir_reg <= wdata[15:0];
                    endcase
                end else begin
                    case (addr[7:0])
                        8'h00: rdata <= {16'h0000, gpio_in}; // Read Input
                        8'h04: rdata <= {16'h0000, out_reg}; // Read Output Reg
                        8'h08: rdata <= {16'h0000, dir_reg}; // Read Dir
                        default: rdata <= 32'b0;
                    endcase
                end
            end else begin
                valid <= 1'b0;
            end
        end
    end

endmodule
