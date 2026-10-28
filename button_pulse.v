
`timescale 1ns / 1ps

module button_pulse #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 10
)(
    input  wire clk,
    input  wire reset,
    input  wire button_in,
    output reg  pulse_out
);

    localparam integer RAW_CYCLES =
        (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    localparam integer DEBOUNCE_CYCLES =
        (RAW_CYCLES < 1) ? 1 : RAW_CYCLES;

    localparam integer COUNT_WIDTH =
        (DEBOUNCE_CYCLES <= 1) ? 1 :
        $clog2(DEBOUNCE_CYCLES + 1);

    reg sync_ff1;
    reg sync_ff2;
    reg debounced_state;

    reg [COUNT_WIDTH-1:0] debounce_count;

    always @(posedge clk) begin
        if (reset) begin
            sync_ff1        <= 1'b0;
            sync_ff2        <= 1'b0;
            debounced_state <= 1'b0;
            debounce_count  <= 0;
            pulse_out       <= 1'b0;
        end
        else begin
            sync_ff1  <= button_in;
            sync_ff2  <= sync_ff1;
            pulse_out <= 1'b0;

            if (sync_ff2 == debounced_state) begin
                debounce_count <= 0;
            end
            else if (debounce_count >= DEBOUNCE_CYCLES - 1) begin
                debounced_state <= sync_ff2;
                debounce_count  <= 0;

                if (sync_ff2)
                    pulse_out <= 1'b1;
            end
            else begin
                debounce_count <= debounce_count + 1'b1;
            end
        end
    end

endmodule
