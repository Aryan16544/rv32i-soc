// =============================================================================
// SoC Timer
// =============================================================================
module soc_timer (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [31:0] addr,
    input wire write,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    output reg valid,
    output wire ready
);

    reg [63:0] mtime;
    reg [63:0] mtimecmp;
    
    assign ready = 1'b1;

    // Timer & Interface Logic Merged
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime <= 64'd0;
            mtimecmp <= 64'hFFFF_FFFF_FFFF_FFFF;
            valid <= 1'b0;
            rdata <= 32'b0;
        end else begin
            // Default increment
            mtime <= mtime + 1'b1;
            
            // Bus Interface overrides increment if writing to mtime
            if (en) begin
                valid <= 1'b1;
                if (write) begin
                    case (addr[7:0])
                        8'h00: mtime[31:0] <= wdata;
                        8'h04: mtime[63:32] <= wdata;
                        8'h08: mtimecmp[31:0] <= wdata;
                        8'h0C: mtimecmp[63:32] <= wdata;
                    endcase
                end else begin
                    case (addr[7:0])
                        8'h00: rdata <= mtime[31:0];
                        8'h04: rdata <= mtime[63:32];
                        8'h08: rdata <= mtimecmp[31:0];
                        8'h0C: rdata <= mtimecmp[63:32];
                        default: rdata <= 32'b0;
                    endcase
                end
            end else begin
                valid <= 1'b0;
            end
        end
    end

endmodule
