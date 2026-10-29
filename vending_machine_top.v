
module vending_machine_top (
    input  wire       CLK100MHZ,
    input  wire       CPU_RESETN,
    input  wire [0:0] SW,
    input  wire       BTNC,
    input  wire       BTNU,
    input  wire       BTNR,

    output wire [7:0] LED,
    output reg  [6:0] SEG,
    output wire       DP,
    output reg  [7:0] AN
);

    wire reset = ~CPU_RESETN;

    // Synchronize the physical push buttons.
    reg start_sync1, start_sync2, start_prev;
    reg coin5_sync1, coin5_sync2, coin5_prev;
    reg coin10_sync1, coin10_sync2, coin10_prev;

    always @(posedge CLK100MHZ) begin
        if (reset) begin
            start_sync1 <= 1'b0;
            start_sync2 <= 1'b0;
            start_prev  <= 1'b0;

            coin5_sync1 <= 1'b0;
            coin5_sync2 <= 1'b0;
            coin5_prev  <= 1'b0;

            coin10_sync1 <= 1'b0;
            coin10_sync2 <= 1'b0;
            coin10_prev  <= 1'b0;
        end
        else begin
            start_sync1 <= BTNC;
            start_sync2 <= start_sync1;
            start_prev  <= start_sync2;

            coin5_sync1 <= BTNU;
            coin5_sync2 <= coin5_sync1;
            coin5_prev  <= coin5_sync2;

            coin10_sync1 <= BTNR;
            coin10_sync2 <= coin10_sync1;
            coin10_prev  <= coin10_sync2;
        end
    end

    wire start_pulse = start_sync2 & ~start_prev;
    wire coin5_pulse = coin5_sync2 & ~coin5_prev;
    wire coin10_pulse = coin10_sync2 & ~coin10_prev;

    wire dispense_a;
    wire dispense_b;
    wire [7:0] amount;
    wire [7:0] change;
    wire busy;

    vending_fsm #(
        .CLK_FREQ_HZ(100_000_000),
        .DISPENSE_SECONDS(1)
    ) vending_controller (
        .clk(CLK100MHZ),
        .reset(reset),
        .start(start_pulse),
        .select_b(SW[0]),
        .coin_5(coin5_pulse),
        .coin_10(coin10_pulse),
        .dispense_a(dispense_a),
        .dispense_b(dispense_b),
        .amount(amount),
        .change(change),
        .busy(busy)
    );

    // Show the amount first, then show the change during dispensing.
    wire [7:0] display_value =
        (dispense_a || dispense_b) ? change : amount;

    assign LED[0]   = dispense_a;
    assign LED[1]   = dispense_b;
    assign LED[2]   = busy;
    assign LED[7:3] = amount[4:0];

    assign DP = 1'b1;

    // Multiplex the two rightmost seven-segment digits.
    reg [15:0] scan_count;
    reg [3:0] digit;
    reg [7:0] display_value_latched;

    always @(posedge CLK100MHZ) begin
        if (reset)
            scan_count <= 16'd0;
        else
            scan_count <= scan_count + 1'b1;
    end

    always @(*) begin
        display_value_latched = display_value;
        digit = 4'd0;
        AN = 8'b11111111;

        case (scan_count[15:14])
            2'b00: begin
                AN = 8'b11111110;
                digit = display_value_latched % 10;
            end

            2'b01: begin
                AN = 8'b11111101;
                digit = display_value_latched / 10;
            end

            default: begin
                AN = 8'b11111111;
                digit = 4'd0;
            end
        endcase

        // Active-low segment patterns: a, b, c, d, e, f, g.
        case (digit)
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
