
`timescale 1ns / 1ps

module vending_machine_top (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,

    input  wire [0:0]  SW,
    input  wire        BTNC,
    input  wire        BTNU,

    output wire [7:0]  LED
);

    wire reset;
    wire dispense_a;
    wire dispense_b;

    wire [7:0] amount;
    wire [7:0] change;

    // Nexys 4 DDR reset button is active-low.
    assign reset = ~CPU_RESETN;

    // Main vending machine controller.
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

    // Hardware status indicators.
    assign LED[0] = dispense_a;
    assign LED[1] = dispense_b;
    assign LED[7:2] = amount[5:0];

endmodule
