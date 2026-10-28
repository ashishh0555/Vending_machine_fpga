
`timescale 1ns / 1ps

module vending_machine_top (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire [0:0]  SW,
    input  wire        BTNC,
    input  wire        BTNU,

    output wire [7:0]  LED,
    output wire [6:0]  SEG,
    output wire        DP,
    output wire [7:0]  AN
);

    wire reset;
    wire dispense_a;
    wire dispense_b;
    wire [7:0] amount;
    wire [7:0] change;

    assign reset = ~CPU_RESETN;

    // Vending machine controller
    vending_fsm vending_controller (
        .clk(CLK100MHZ),
        .reset(reset),
        .select_b(SW[0]),
        .coin_5(BTNC),
        .coin_10(BTNU),
        .dispense_a(dispense_a),
        .dispense_b(dispense_b),
        .amount(amount),
        .change(change)
    );

    // Display the amount inserted.
    seven_segment display_driver (
        .clk(CLK100MHZ),
        .reset(reset),
        .value({8'b0, amount}),
        .SEG(SEG),
        .DP(DP),
        .AN(AN)
    );

    // LEDs show dispensing status.
    assign LED[0] = dispense_a;
    assign LED[1] = dispense_b;

    // LEDs show the lower six bits of the inserted amount.
    assign LED[7:2] = amount[5:0];

endmodule
