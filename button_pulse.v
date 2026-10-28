
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

    localparam integer DEBOUNCE_CYCLES =
        (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    localparam integer COUNT_WIDTH =
        (DEBOUNCE_CYCLES <= 1) ? 1 : $clog2(DEBOUNCE_CYCLES + 1);

    // Two-stage synchronizer
    reg sync_ff1;
    reg sync_ff2;

    // Debounce state
    reg debounced_state;
    reg [COUNT_WIDTH-1:0] debounce_count;

    always @(posedge clk) begin
        if (reset) begin
            sync_ff1       <= 1'b0;
            sync_ff2       <= 1'b0;
            debounced_state <= 1'b0;
            debounce_count <= {COUNT_WIDTH{1'b0}};
            pulse_out      <= 1'b0;
        end else begin
            // Synchronize the asynchronous physical button
            sync_ff1 <= button_in;
            sync_ff2 <= sync_ff1;

            // Pulse is low by default; asserted for one clock only
            pulse_out <= 1'b0;

            if (sync_ff2 == debounced_state) begin
                debounce_count <= {COUNT_WIDTH{1'b0}};
            end else begin
                if (debounce_count >= DEBOUNCE_CYCLES - 1) begin
                    debounced_state <= sync_ff2;
                    debounce_count <= {COUNT_WIDTH{1'b0}};

                    // Generate pulse only on a confirmed press
                    if (sync_ff2 == 1'b1)
                        pulse_out <= 1'b1;
                end else begin
                    debounce_count <= debounce_count + 1'b1;
                end
            end
        end
    end

endmodule
