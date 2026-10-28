
`timescale 1ns / 1ps

module seven_segment (
    input  wire       clk,
    input  wire       reset,
    input  wire [15:0] value,

    output reg  [6:0] SEG,
    output reg        DP,
    output reg  [7:0] AN
);

    reg [16:0] refresh_counter;
    reg [1:0] digit_select;
    reg [3:0] digit;

    wire [3:0] thousands;
    wire [3:0] hundreds;
    wire [3:0] tens;
    wire [3:0] ones;

    assign thousands = value / 1000;
    assign hundreds  = (value / 100) % 10;
    assign tens      = (value / 10) % 10;
    assign ones      = value % 10;

    // Refresh the display using the onboard clock.
    always @(posedge clk) begin
        if (reset) begin
            refresh_counter <= 0;
            digit_select <= 0;
        end
        else begin
            refresh_counter <= refresh_counter + 1'b1;

            if (refresh_counter == 17'd99999) begin
                refresh_counter <= 0;
                digit_select <= digit_select + 1'b1;
            end
        end
    end

    // Select one decimal digit.
    always @(*) begin
        case (digit_select)
            2'd0: begin
                digit = ones;
                AN = 8'b11111110;
            end

            2'd1: begin
                digit = tens;
                AN = 8'b11111101;
            end

            2'd2: begin
                digit = hundreds;
                AN = 8'b11111011;
            end

            2'd3: begin
                digit = thousands;
                AN = 8'b11110111;
            end

            default: begin
                digit = 0;
                AN = 8'b11111111;
            end
        endcase

        DP = 1'b1;

        // Active-low segment encoding: {a,b,c,d,e,f,g}
        case (digit)
            4'd0: SEG = 7'b0000001;
            4'd1: SEG = 7'b1001111;
            4'd2: SEG = 7'b0010010;
            4'd3: SEG = 7'b0000110;
            4'd4: SEG = 7'b1001100;
            4'd5: SEG = 7'b0100100;
            4'd6: SEG = 7'b0100000;
            4'd7: SEG = 7'b0001111;
            4'd8: SEG = 7'b0000000;
            4'd9: SEG = 7'b0000100;
            default: SEG = 7'b1111111;
        endcase
    end

endmodule
