
`timescale 1ns / 1ps

module vending_fsm #(
    parameter integer DISPENSE_SECONDS = 1
)(
    input  wire       clk,
    input  wire       reset,

    input  wire       select_b,    // 0 = Product A, 1 = Product B
    input  wire       coin_5,
    input  wire       coin_10,

    output reg        dispense_a,
    output reg        dispense_b,
    output reg [7:0]  amount,
    output reg [7:0]  change
);

    localparam [2:0]
        IDLE     = 3'd0,
        COLLECT  = 3'd1,
        DISPENSE = 3'd2,
        SHOW_CHANGE = 3'd3;

    reg [2:0] state;
    reg [7:0] price;
    reg       selected_b;
    reg [7:0] next_amount;

    // Use a parameter so simulation can use a small clock count.
    reg [26:0] dispense_counter;
    localparam [26:0] DISPENSE_CYCLES =
        27'd100_000_000 * DISPENSE_SECONDS;

    always @(posedge clk) begin
        if (reset) begin
            state            <= IDLE;
            amount           <= 0;
            change           <= 0;
            dispense_a       <= 0;
            dispense_b       <= 0;
            selected_b       <= 0;
            price            <= 10;
            next_amount      <= 0;
            dispense_counter <= 0;
        end
        else begin
            dispense_a <= 0;
            dispense_b <= 0;

            case (state)

                IDLE: begin
                    amount <= 0;
                    change <= 0;
                    selected_b <= select_b;
                    price <= select_b ? 8'd20 : 8'd10;
                    state <= COLLECT;
                end

                COLLECT: begin
                    if (coin_5 && !coin_10) begin
                        next_amount = amount + 8'd5;
                        amount <= next_amount;

                        if (next_amount >= price)
                            state <= DISPENSE;
                    end
                    else if (coin_10 && !coin_5) begin
                        next_amount = amount + 8'd10;
                        amount <= next_amount;

                        if (next_amount >= price)
                            state <= DISPENSE;
                    end
                end

                DISPENSE: begin
                    dispense_a <= !selected_b;
                    dispense_b <= selected_b;

                    if (amount > price)
                        change <= amount - price;
                    else
                        change <= 0;

                    dispense_counter <= 0;
                    state <= SHOW_CHANGE;
                end

                SHOW_CHANGE: begin
                    if (dispense_counter >= DISPENSE_CYCLES - 1) begin
                        dispense_counter <= 0;
                        state <= IDLE;
                    end
                    else begin
                        dispense_counter <= dispense_counter + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    amount <= 0;
                    change <= 0;
                    dispense_counter <= 0;
                end

            endcase
        end
    end

endmodule
