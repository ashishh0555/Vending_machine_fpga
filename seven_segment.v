
`timescale 1ns / 1ps

module seven_segment (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] value,
    output reg  [6:0] SEG,
    output reg  [7:0] AN,
    output wire       DP
);

    // Nexys 4 DDR seven-segment display uses active-low outputs
    assign DP = 1'b1;  // Decimal point off

    reg [16:0] refresh_counter;
    wire [1:0] digit_select;

    reg [3:0] digit_value;

    // Refresh digits fast enough to avoid visible flicker
    always @(posedge clk) begin
        if (reset)
            refresh_counter <= 17'd0;
        else
            refresh_counter <= refresh_counter + 1'b1;
    end

    assign digit_select = refresh_counter[16:15];

    // Select the digit to display
    always @(*) begin
        case (digit_select)
            2'b00: begin
                AN = 8'b11111110;
                digit_value = value % 10;
            end

            2'b01: begin
                AN = 8'b11111101;
                digit_value = (value / 10) % 10;
            end

            2'b10: begin
                AN = 8'b11111011;
                digit_value = (value / 100) % 10;
            end

            2'b11: begin
                AN = 8'b11110111;
                digit_value = (value / 1000) % 10;
            end

            default: begin
                AN = 8'b11111111;
                digit_value = 4'd0;
            end
        endcase

        // Active-low segment encoding: SEG = {g,f,e,d,c,b,a}
        case (digit_value)
            4'd0: SEG = 7'b1000000;
            4'd1: SEG = 7'b1111001;
            4'd2: SEG = 7'b0100100;
            4'd3: SEG = 7'b0110000;
            4'd4: SEG = 7'b0011001;
            4'd5: SEG = 7'b0010010;
            4'd6: SEG = 7'b0000010;
            4'd7: SEG = 7'b1111000;
            4'd8: SEG = 7'b0000000;
            4'd9: SEG = 7'b0010000;
            default: SEG = 7'b1111111;
        endcase
    end

endmodule
