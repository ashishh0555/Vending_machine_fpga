
`timescale 1ns / 1ps

module clock_divider #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer TICK_FREQ_HZ = 1
)(
    input  wire clk,
    input  wire reset,
    output reg  tick
);

    localparam integer DIVISOR = CLK_FREQ_HZ / TICK_FREQ_HZ;

    localparam integer COUNTER_WIDTH =
        (DIVISOR <= 1) ? 1 : $clog2(DIVISOR);

    reg [COUNTER_WIDTH-1:0] counter;

    initial begin
        if (CLK_FREQ_HZ < 1 || TICK_FREQ_HZ < 1 ||
            TICK_FREQ_HZ > CLK_FREQ_HZ ||
            CLK_FREQ_HZ % TICK_FREQ_HZ != 0)
            $error("Invalid clock divider parameters");
    end

    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            tick    <= 1'b0;
        end
        else if (counter == DIVISOR - 1) begin
            counter <= 0;
            tick    <= 1'b1;
        end
        else begin
            counter <= counter + 1'b1;
            tick    <= 1'b0;
        end
    end

endmodule
