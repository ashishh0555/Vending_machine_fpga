
`timescale 1ns / 1ps

module clock_divider #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer TICK_FREQ_HZ = 1
)(
    input  wire clk,
    input  wire reset,
    output reg  tick
);

    localparam integer DIVISOR =
        (TICK_FREQ_HZ < 1) ? 1 :
        (CLK_FREQ_HZ / TICK_FREQ_HZ);

    localparam integer COUNT_WIDTH =
        (DIVISOR <= 1) ? 1 : $clog2(DIVISOR);

    reg [COUNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter <= {COUNT_WIDTH{1'b0}};
            tick    <= 1'b0;
        end else begin
            tick <= 1'b0;

            if (counter >= DIVISOR - 1) begin
                counter <= {COUNT_WIDTH{1'b0}};
                tick    <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule
