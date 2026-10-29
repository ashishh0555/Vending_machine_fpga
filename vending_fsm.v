
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

    // FSM states
    localparam [1:0]
        IDLE        = 2'b00,
        COLLECT     = 2'b01,
        SHOW_AMOUNT = 2'b10,
        DISPENSE    = 2'b11;

    // Duration of amount and dispensing displays
    localparam integer DISPENSE_CYCLES =
        (CLK_FREQ_HZ > 0 && DISPENSE_SECONDS > 0)
        ? CLK_FREQ_HZ * DISPENSE_SECONDS : 1;

    localparam integer COUNT_WIDTH =
        (DISPENSE_CYCLES <= 1)
        ? 1 : $clog2(DISPENSE_CYCLES);

    reg [1:0] state;
    reg [7:0] price;
    reg       selected_b;
    reg [COUNT_WIDTH-1:0] counter;

    // Coin value and updated total
    wire [8:0] coin_value;
    wire [8:0] next_amount;

    assign coin_value =
        (coin_5 && !coin_10) ? 9'd5 :
        (coin_10 && !coin_5) ? 9'd10 :
                               9'd0;

    assign next_amount = {1'b0, amount} + coin_value;

    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            price      <= 8'd10;
            selected_b <= 1'b0;
            amount     <= 8'd0;
            change     <= 8'd0;
            dispense_a <= 1'b0;
            dispense_b <= 1'b0;
            busy       <= 1'b0;
            counter    <= {COUNT_WIDTH{1'b0}};
        end
        else begin
            // Default: products are not dispensing
            dispense_a <= 1'b0;
            dispense_b <= 1'b0;

            case (state)

                IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        selected_b <= select_b;
                        price       <= select_b ? 8'd20 : 8'd10;
                        amount      <= 8'd0;
                        change      <= 8'd0;
                        counter     <= {COUNT_WIDTH{1'b0}};
                        busy        <= 1'b1;
                        state       <= COLLECT;
                    end
                end

                COLLECT: begin
                    busy <= 1'b1;

                    // Accept one coin denomination at a time
                    if (coin_5 ^ coin_10) begin

                        // Update the accumulated payment
                        if (next_amount > 9'd255)
                            amount <= 8'd255;
                        else
                            amount <= next_amount[7:0];

                        // Once enough money is inserted,
                        // calculate change and show the total first
                        if (next_amount >= {1'b0, price}) begin
                            if (next_amount > 9'd255)
                                change <= 8'd255 - price;
                            else
                                change <= next_amount[7:0] - price;

                            counter <= {COUNT_WIDTH{1'b0}};
                            state   <= SHOW_AMOUNT;
                        end
                    end
                end

                SHOW_AMOUNT: begin
                    // Keep the final inserted amount on display
                    busy       <= 1'b1;
                    dispense_a <= 1'b0;
                    dispense_b <= 1'b0;

                    if (counter >= DISPENSE_CYCLES - 1) begin
                        counter <= {COUNT_WIDTH{1'b0}};
                        state   <= DISPENSE;
                    end
                    else begin
                        counter <= counter + 1'b1;
                    end
                end

                DISPENSE: begin
                    // Display change while the product is dispensing
                    busy       <= 1'b1;
                    dispense_a <= !selected_b;
                    dispense_b <= selected_b;

                    if (counter >= DISPENSE_CYCLES - 1) begin
                        dispense_a <= 1'b0;
                        dispense_b <= 1'b0;
                        busy       <= 1'b0;
                        amount     <= 8'd0;
                        change     <= 8'd0;
                        counter    <= {COUNT_WIDTH{1'b0}};
                        state      <= IDLE;
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
                    busy       <= 1'b0;
                    counter    <= {COUNT_WIDTH{1'b0}};
                end

            endcase
        end
    end

endmodule
