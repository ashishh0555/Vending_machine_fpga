
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

    localparam [1:0] IDLE        = 2'd0;
    localparam [1:0] COLLECT     = 2'd1;
    localparam [1:0] SHOW_AMOUNT = 2'd2;
    localparam [1:0] DISPENSE    = 2'd3;

    localparam integer TIMER_LIMIT =
        CLK_FREQ_HZ * DISPENSE_SECONDS;

    reg [1:0] state;
    reg [31:0] timer_count;

    reg selected_b;
    reg [7:0] product_price;

    reg [7:0] next_amount;
    reg [7:0] coin_value;

    always @(*) begin
        if (coin_10)
            coin_value = 8'd10;
        else if (coin_5)
            coin_value = 8'd5;
        else
            coin_value = 8'd0;

        next_amount = amount + coin_value;

        if (selected_b)
            product_price = 8'd20;
        else
            product_price = 8'd10;
    end

    always @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            timer_count <= 32'd0;
            selected_b  <= 1'b0;
            amount      <= 8'd0;
            change      <= 8'd0;
            dispense_a  <= 1'b0;
            dispense_b  <= 1'b0;
            busy        <= 1'b0;
        end
        else begin
            dispense_a <= 1'b0;
            dispense_b <= 1'b0;

            case (state)

                IDLE: begin
                    busy        <= 1'b0;
                    timer_count <= 32'd0;
                    amount      <= 8'd0;
                    change      <= 8'd0;

                    if (start) begin
                        selected_b <= select_b;
                        busy       <= 1'b1;
                        state      <= COLLECT;
                    end
                end

                COLLECT: begin
                    busy <= 1'b1;

                    // Accept one coin pulse at a time.
                    if (coin_5 ^ coin_10) begin
                        amount <= next_amount;

                        if (next_amount >= product_price) begin
                            change      <= next_amount - product_price;
                            timer_count <= 32'd0;
                            state       <= SHOW_AMOUNT;
                        end
                    end
                end

                // Keep the final inserted amount on the display.
                SHOW_AMOUNT: begin
                    busy <= 1'b1;

                    if (timer_count >= TIMER_LIMIT - 1) begin
                        timer_count <= 32'd0;
                        state       <= DISPENSE;
                    end
                    else begin
                        timer_count <= timer_count + 1'b1;
                    end
                end

                // During dispensing, the top module displays change.
                DISPENSE: begin
                    busy <= 1'b1;

                    if (selected_b)
                        dispense_b <= 1'b1;
                    else
                        dispense_a <= 1'b1;

                    if (timer_count >= TIMER_LIMIT - 1) begin
                        timer_count <= 32'd0;
                        amount      <= 8'd0;
                        change      <= 8'd0;
                        busy        <= 1'b0;
                        state       <= IDLE;
                    end
                    else begin
                        timer_count <= timer_count + 1'b1;
                    end
                end

                default: begin
                    state       <= IDLE;
                    timer_count <= 32'd0;
                    amount      <= 8'd0;
                    change      <= 8'd0;
                    busy        <= 1'b0;
                end

            endcase
        end
    end

endmodule
