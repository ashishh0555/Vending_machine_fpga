
`timescale 1ns / 1ps

module button_pulse #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 10
)(
    input  wire clk,
    input  wire reset,
    input  wire button_in,
    output reg  pulse
);

    localparam integer COUNT_MAX =
        (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    localparam integer COUNT_WIDTH =
        (COUNT_MAX <= 1) ? 1 : $clog2(COUNT_MAX);

    reg sync_ff1;
    reg sync_ff2;
    reg stable_button;
    reg [COUNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            sync_ff1     <= 1'b0;
            sync_ff2     <= 1'b0;
            stable_button <= 1'b0;
            counter      <= 0;
            pulse        <= 1'b0;
        end
        else begin
            sync_ff1 <= button_in;
            sync_ff2 <= sync_ff1;
            pulse <= 1'b0;

            if (sync_ff2 == stable_button) begin
                counter <= 0;
            end
            else if (counter == COUNT_MAX - 1) begin
                stable_button <= sync_ff2;
                counter <= 0;

                if (sync_ff2)
                    pulse <= 1'b1;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule
