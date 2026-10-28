
`timescale 1ns / 1ps

module vending_fsm (
    input  wire       clk,
    input  wire       reset,

    input  wire       select_b,    // 0 = Product A, 1 = Product B
    input  wire       coin_5,      // One pulse for a Rs. 5 coin
    input  wire       coin_10,     // One pulse for a Rs. 10 coin

    output reg        dispense_a,
    output reg        dispense_b,
    output reg [7:0]  amount,
    output reg [7:0]  change
);

    localparam [2:0]
        IDLE     = 3'd0,
        COLLECT  = 3'd1,
        DISPENSE = 3'd2,
        RETURN   = 3'd3;

    reg [2:0] state;
    reg [7:0] next_amount;
    reg [7:0] price;
    reg       selected_b;

    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            amount     <= 0;
            change     <= 0;
            dispense_a <= 0;
            dispense_b <= 0;
            selected_b <= 0;
            price      <= 10;
        end
        else begin
            // Outputs are pulses unless otherwise stated.
            dispense_a <= 0;
            dispense_b <= 0;
            change     <= 0;

            case (state)

                IDLE: begin
                    amount <= 0;
                    price <= select_b ? 8'd20 : 8'd10;
                    selected_b <= select_b;
                    state <= COLLECT;
                end

                COLLECT: begin
                    // Latch the product selection while collecting.
                    // Accept only one coin input at a time.
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
                        dispense_b <= 1;
                    else
                        dispense_a <= 1;

                    if (amount > price) begin
                        change <= amount - price;
                        state <= RETURN;
                    end
                    else begin
                        state <= IDLE;
                    end
                end

                RETURN: begin
                    state <= IDLE;
                end

                default: begin
                    state  <= IDLE;
                    amount <= 0;
                    change <= 0;
                end

            endcase
        end
    end

endmodule
