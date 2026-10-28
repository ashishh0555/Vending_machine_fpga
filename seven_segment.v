
`timescale 1ns / 1ps

module seven_segment #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer REFRESH_HZ  = 1000
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] value,
    output reg  [6:0] seg,
    output wire       dp,
    output reg  [7:0] an
);

    localparam integer RAW_DIV =
        (REFRESH_HZ > 0) ?
        (CLK_FREQ_HZ / (2 * REFRESH_HZ)) : 1;

    localparam integer HALF_PERIOD =
        (RAW_DIV < 1) ? 1 : RAW_DIV;

    localparam integer COUNT_WIDTH =
        (HALF_PERIOD <= 1) ? 1 : $clog2(HALF_PERIOD);

    reg [COUNT_WIDTH-1:0] refresh_count;
    reg scan_digit;

    reg [3:0] digit_value;
    reg [7:0] display_value;

    // Decimal point is active-low: 1 means OFF.
    assign dp = 1'b1;

    // Multiplex the two rightmost digits.
    always @(posedge clk) begin
        if (reset) begin
            refresh_count <= 0;
            scan_digit    <= 1'b0;
        end
        else begin
            if (refresh_count >= HALF_PERIOD - 1) begin
                refresh_count <= 0;
                scan_digit    <= ~scan_digit;
            end
            else begin
                refresh_count <= refresh_count + 1'b1;
            end
        end
    end

    // Convert the input value into decimal tens and units.
    always @(*) begin
        if (value > 8'd99)
            display_value = 8'd99;
        else
            display_value = value;

        if (scan_digit == 1'b0) begin
            digit_value = display_value % 10;
            an = 8'b11111110;  // Units digit
        end
        else begin
            digit_value = display_value / 10;
            an = 8'b11111101;  // Tens digit
        end

        // Active-low seven-segment encoding: abcdefg
        case (digit_value)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
