
`timescale 1ns / 1ps

module vending_fsm #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DISPENSE_SECONDS = 1
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire       select_b,
    input  wire       coin_5,
    input  wire       coin_10,

    output reg        dispense_a,
    output reg        dispense_b,
    output reg [7:0]  amount,
    output reg [7:0]  change,
    output reg        busy
);

    localparam [2:0]
        IDLE       = 3'd0,
        COLLECT    = 3'd1,
        DISPENSE   = 3'd2,
        SHOW_CHANGE = 3'd3;

    localparam integer DISPENSE_CYCLES =
        CLK_FREQ_HZ * DISPENSE_SECONDS;

    localparam integer COUNT_WIDTH =
        (DISPENSE_CYCLES <= 1) ? 1 : $clog2(DISPENSE_CYCLES);

    reg [2:0] state;
    reg [7:0] price;
    reg       selected_b;
    reg [7:0] accepted_amount;
    reg [COUNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            state           <= IDLE;
            amount          <= 8'd0;
            change          <= 8'd0;
            dispense_a      <= 1'b0;
            dispense_b      <= 1'b0;
            busy             <= 1'b0;
            price           <= 8'd10;
            selected_b      <= 1'b0;
            accepted_amount <= 8'd0;
            counter         <= 0;
        end
        else begin
            // Default: dispensing indicators are inactive.
            dispense_a <= 1'b0;
            dispense_b <= 1'b0;

            case (state)

                IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        selected_b      <= select_b;
                        price           <= select_b ? 8'd20 : 8'd10;
                        amount          <= 8'd0;
                        change          <= 8'd0;
                        accepted_amount <= 8'd0;
                        counter         <= 0;
                        busy            <= 1'b1;
                        state           <= COLLECT;
                    end
                end

                COLLECT: begin
                    busy <= 1'b1;

                    // Accept one denomination at a time.
                    if (coin_5 && !coin_10) begin
                        accepted_amount = amount + 8'd5;
                        amount <= accepted_amount;

                        if (accepted_amount >= price)
                            state <= DISPENSE;
                    end
                    else if (coin_10 && !coin_5) begin
                        accepted_amount = amount + 8'd10;
                        amount <= accepted_amount;

                        if (accepted_amount >= price)
                            state <= DISPENSE;
                    end
                end

                DISPENSE: begin
                    dispense_a <= !selected_b;
                    dispense_b <= selected_b;

                    if (amount > price)
                        change <= amount - price;
                    else
                        change <= 8'd0;

                    counter <= 0;
                    state <= SHOW_CHANGE;
                end

                SHOW_CHANGE: begin
                    busy <= 1'b1;
                    dispense_a <= !selected_b;
                    dispense_b <= selected_b;

                    if (counter >= DISPENSE_CYCLES - 1) begin
                        dispense_a <= 1'b0;
                        dispense_b <= 1'b0;
                        counter <= 0;
                        busy <= 1'b0;
                        state <= IDLE;
                    end
                    else begin
                        counter <= counter + 1'b1;
                    end
                end

                default: begin
                    state      <= IDLE;
                    amount     <= 8'd0;
                    change     <= 8'd0;
                    dispense_a <= 1'b0;
                    dispense_b <= 1'b0;
                    busy        <= 1'b0;
                    counter    <= 0;
                end

            endcase
        end
    end

endmodule
