
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
    wire coin5_pulse;
    wire coin10_pulse;

    wire dispense_a;
    wire dispense_b;
    wire [7:0] amount;
    wire [7:0] change;

    assign reset = ~CPU_RESETN;

    // Debounce and generate one pulse for each coin-button press.
    button_pulse coin5_button (
        .clk(CLK100MHZ),
        .reset(reset),
        .button_in(BTNC),
        .pulse(coin5_pulse)
    );

    button_pulse coin10_button (
        .clk(CLK100MHZ),
        .reset(reset),
        .button_in(BTNU),
        .pulse(coin10_pulse)
    );

    // Main vending machine controller.
    vending_fsm vending_controller (
        .clk(CLK100MHZ),
        .reset(reset),
        .select_b(SW[0]),
        .coin_5(coin5_pulse),
        .coin_10(coin10_pulse),
        .dispense_a(dispense_a),
        .dispense_b(dispense_b),
        .amount(amount),
        .change(change)
    );

    // Display the accumulated amount.
    seven_segment display_driver (
        .clk(CLK100MHZ),
        .reset(reset),
        .value({8'b0, amount}),
        .SEG(SEG),
        .DP(DP),
        .AN(AN)
    );

    // LED indicators.
    assign LED[0] = dispense_a;
    assign LED[1] = dispense_b;
    assign LED[7:2] = amount[5:0];

endmodule
