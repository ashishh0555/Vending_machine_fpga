
`timescale 1ns / 1ps

module clock_divider #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer OUT_FREQ_HZ = 1
)(
    input  wire clk,
    input  wire reset,
    output reg  clk_out
);

    localparam integer HALF_PERIOD =
        (OUT_FREQ_HZ > 0) ? (CLK_FREQ_HZ / (2 * OUT_FREQ_HZ)) : 1;

    localparam integer COUNT_WIDTH =
        (HALF_PERIOD <= 1) ? 1 : $clog2(HALF_PERIOD);

    reg [COUNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end
        else begin
            if (counter >= HALF_PERIOD - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule
