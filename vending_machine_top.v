
`timescale 1ns / 1ps

module vending_machine_top (
    input  wire       CLK100MHZ,
    input  wire       CPU_RESETN,
    input  wire [0:0] SW,
    input  wire       BTNC,
    input  wire       BTNU,

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

    // Nexys 4 DDR CPU_RESETN is active-low
    assign reset = ~CPU_RESETN;

    // BTNC starts a transaction
    button_pulse start_button (
        .clk(CLK100MHZ),
        .reset(reset),
        .button_in(BTNC),
        .pulse_out(start_pulse)
    );

    // BTNU inserts Rs. 5
    button_pulse coin5_button (
        .clk(CLK100MHZ),
        .reset(reset),
        .button_in(BTNU),
        .pulse_out(coin5_pulse)
    );

    // NOTE:
    // The current board interface has only two buttons assigned:
    // BTNC = start, BTNU = Rs. 5.
    // A separate Rs. 10 input must be assigned to another button
    // or implemented using a switch in a later revision.

    // Vending machine controller
    vending_fsm #(
        .CLK_FREQ_HZ(100_000_000),
        .DISPENSE_SECONDS(1)
    ) vending_controller (
        .clk(CLK100MHZ),
        .reset(reset),
        .start(start_pulse),
        .select_b(SW[0]),
        .coin_5(coin5_pulse),
        .coin_10(1'b0),
        .dispense_a(dispense_a),
        .dispense_b(dispense_b),
        .amount(amount),
        .change(change),
        .busy(busy)
    );

    // LED indicators
    assign LED[0]   = dispense_a;
    assign LED[1]   = dispense_b;
    assign LED[2]   = busy;
    assign LED[7:3] = amount[4:0];

    // Display change when available; otherwise show amount inserted
    wire [7:0] display_value;
    assign display_value = (change != 0) ? change : amount;

    seven_segment display_driver (
        .clk(CLK100MHZ),
        .reset(reset),
        .value(display_value),
        .SEG(SEG),
        .AN(AN),
        .DP(DP)
    );

endmodule
