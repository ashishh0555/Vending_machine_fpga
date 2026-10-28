
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
        DISPENSE    = 2'b10,
        SHOW_CHANGE = 2'b11;

    // Number of clock cycles for the dispense indication
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

    // Combinational next payment amount
    wire [8:0] next_amount;

    assign next_amount =
        {1'b0, amount}
        + (coin_5 && !coin_10 ? 9'd5 :
           coin_10 && !coin_5 ? 9'd10 : 9'd0);

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
        end else begin

            // Default outputs
            dispense_a <= 1'b0;
            dispense_b <= 1'b0;

            case (state)

                IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        selected_b <= select_b;
                        price      <= select_b ? 8'd20 : 8'd10;
                        amount     <= 8'd0;
                        change     <= 8'd0;
                        counter    <= {COUNT_WIDTH{1'b0}};
                        busy       <= 1'b1;
                        state      <= COLLECT;
                    end
                end

                COLLECT: begin
                    busy <= 1'b1;

                    // Accept only one coin denomination per clock.
                    if ((coin_5 ^ coin_10) == 1'b1) begin
                        if (next_amount > 9'd255) begin
                            // Prevent 8-bit amount overflow.
                            amount <= 8'd255;
                        end else begin
                            amount <= next_amount[7:0];
                        end

                        if (next_amount >= {1'b0, price}) begin
                            state <= DISPENSE;
                        end
                    end
                end

                DISPENSE: begin
                    // Assert the selected product indicator.
                    dispense_a <= !selected_b;
                    dispense_b <= selected_b;

                    // Calculate change from the accepted payment.
                    if (amount >= price)
                        change <= amount - price;
                    else
                        change <= 8'd0;

                    counter <= {COUNT_WIDTH{1'b0}};
                    state   <= SHOW_CHANGE;
                end

                
                SHOW_CHANGE: begin
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
