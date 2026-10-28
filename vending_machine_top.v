
`timescale 1ns / 1ps

module vending_machine_top (
    input  wire       CLK100MHZ,
    input  wire       CPU_RESETN,
    input  wire [0:0] SW,

    input  wire       BTNC,  // Start transaction
    input  wire       BTNU,  // Insert Rs. 5
    input  wire       BTNR,  // Insert Rs. 10

    output wire [7:0] LED,
    output wire [6:0] SEG,
    output wire       DP,
    output wire [7:0] AN
);

    wire reset;

    wire start_pulse;
    wire coin5_pulse;
    wire coin10_pulse;

    wire dispense_a;
    wire dispense_b;
    wire busy;

    wire [7:0] amount;
    wire [7:0] change;
    wire [7:0] display_value;

    // Nexys 4 DDR reset is active-low.
    assign reset = ~CPU_RESETN;

    // Center button: start transaction.
    button_pulse start_button (
        .clk(CLK100MHZ),
        .reset(reset),
        .button_in(BTNC),
        .pulse_out(start_pulse)
    );

    // Up button: insert Rs. 5.
    button_pulse coin5_button (
        .clk(CLK100MHZ),
        .reset(reset),
        .button_in(BTNU),
        .pulse_out(coin5_pulse)
    );

    // Right button: insert Rs. 10.
    button_pulse coin10_button (
        .clk(CLK100MHZ),
        .reset(reset),
        .button_in(BTNR),
        .pulse_out(coin10_pulse)
    );

    // Main vending machine controller.
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

    // LEDs:
    // LED[0] = Product A dispensing
    // LED[1] = Product B dispensing
    // LED[2] = Transaction busy
    // LED[7:3] = Low five bits of inserted amount
    assign LED[0]   = dispense_a;
    assign LED[1]   = dispense_b;
    assign LED[2]   = busy;
    assign LED[7:3] = amount[4:0];

    // Show change while dispensing.
    // Otherwise show the amount inserted.
    assign display_value =
        (dispense_a || dispense_b) ? change : amount;

    // Seven-segment display driver.
    seven_segment display_driver (
        .clk(CLK100MHZ),
        .reset(reset),
        .value(display_value),
        .seg(SEG),
        .an(AN),
        .dp(DP)
    );

endmodule
