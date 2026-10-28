
`timescale 1ns / 1ps

module vending_fsm (
    input  wire       clk,
    input  wire       reset,

    input  wire       select_b,
    input  wire       coin_5,
    input  wire       coin_10,

    output reg        dispense_a,
    output reg        dispense_b,
    output reg [7:0]  amount,
    output reg [7:0]  change
);

    localparam [1:0]
        IDLE     = 2'b00,
        COLLECT  = 2'b01,
        DISPENSE = 2'b10;

    reg [1:0] state;
    reg [7:0] price;
    reg       selected_b;
    reg [7:0] next_amount;

    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            amount     <= 8'd0;
            change     <= 8'd0;
            dispense_a <= 1'b0;
            dispense_b <= 1'b0;
            selected_b <= 1'b0;
            price      <= 8'd10;
            next_amount <= 8'd0;
        end
        else begin
            // Default pulse outputs to zero each clock cycle.
            dispense_a <= 1'b0;
            dispense_b <= 1'b0;
            change     <= 8'd0;

            case (state)

                IDLE: begin
                    amount <= 8'd0;
                    price <= select_b ? 8'd20 : 8'd10;
                    selected_b <= select_b;
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
                    if (selected_b)
                        dispense_b <= 1'b1;
                    else
                        dispense_a <= 1'b1;

                    if (amount > price)
                        change <= amount - price;

                    // End the transaction after dispensing.
                    state <= IDLE;
                end

                default: begin
                    state  <= IDLE;
                    amount <= 8'd0;
                    change <= 8'd0;
                end

            endcase
        end
    end

endmodule
