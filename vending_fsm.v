
`timescale 1ns / 1ps

module vending_fsm #(
    parameter integer DISPENSE_CYCLES = 100_000_000
)(
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
        IDLE     = 2'd0,
        COLLECT  = 2'd1,
        DISPENSE = 2'd2,
        SHOW     = 2'd3;

    reg [1:0] state;
    reg [7:0] price;
    reg       selected_b;
    reg [7:0] next_amount;

    // Counter wide enough for the default 100-million-cycle interval.
    localparam integer COUNT_WIDTH =
        (DISPENSE_CYCLES <= 1) ? 1 : $clog2(DISPENSE_CYCLES);

    reg [COUNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            amount      <= 0;
            change      <= 0;
            dispense_a  <= 0;
            dispense_b  <= 0;
            selected_b  <= 0;
            price       <= 10;
            next_amount <= 0;
            counter     <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    dispense_a <= 0;
                    dispense_b <= 0;
                    amount     <= 0;
                    change     <= 0;
                    counter    <= 0;

                    selected_b <= select_b;
                    price      <= select_b ? 8'd20 : 8'd10;
                    state      <= COLLECT;
                end

                COLLECT: begin
                    dispense_a <= 0;
                    dispense_b <= 0;

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

                    counter <= 0;
                    state <= SHOW;
                end

                SHOW: begin
                    // Keep dispensing indicator and change visible.
                    dispense_a <= !selected_b;
                    dispense_b <= selected_b;

                    if (counter >= DISPENSE_CYCLES - 1) begin
                        dispense_a <= 0;
                        dispense_b <= 0;
                        counter <= 0;
                        state <= IDLE;
                    end
                    else begin
                        counter <= counter + 1'b1;
                    end
                end

                default: begin
                    state       <= IDLE;
                    amount      <= 0;
                    change      <= 0;
                    dispense_a  <= 0;
                    dispense_b  <= 0;
                    counter     <= 0;
                end

            endcase
        end
    end

endmodule
