
`timescale 1ns / 1ps

module vending_machine_tb;

    reg clk;
    reg reset;
    reg start;
    reg select_b;
    reg coin_5;
    reg coin_10;

    wire dispense_a;
    wire dispense_b;
    wire [7:0] amount;
    wire [7:0] change;
    wire busy;

    // Short dispensing time for simulation
    vending_fsm #(
        .CLK_FREQ_HZ(5),
        .DISPENSE_SECONDS(1)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .select_b(select_b),
        .coin_5(coin_5),
        .coin_10(coin_10),
        .dispense_a(dispense_a),
        .dispense_b(dispense_b),
        .amount(amount),
        .change(change),
        .busy(busy)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Insert one Rs. 5 coin
    task insert_coin5;
        begin
            @(negedge clk);
            coin_5 = 1'b1;
            @(negedge clk);
            coin_5 = 1'b0;
        end
    endtask

    // Insert one Rs. 10 coin
    task insert_coin10;
        begin
            @(negedge clk);
            coin_10 = 1'b1;
            @(negedge clk);
            coin_10 = 1'b0;
        end
    endtask

    // Begin a transaction
    task start_transaction;
        input product_b;
        begin
            @(negedge clk);
            select_b = product_b;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    // Reset between tests
    task reset_fsm;
        begin
            @(negedge clk);
            reset = 1'b1;
            start = 1'b0;
            select_b = 1'b0;
            coin_5 = 1'b0;
            coin_10 = 1'b0;

            repeat (2) @(negedge clk);

            reset = 1'b0;
            @(negedge clk);
        end
    endtask

    // Wait for a product and verify results
    task check_result;
        input expected_product_b;
        input [7:0] expected_amount;
        input [7:0] expected_change;
        begin
            // Prevent an indefinite wait if dispensing never occurs.
            fork
                begin
                    if (expected_product_b)
                        wait (dispense_b == 1'b1);
                    else
                        wait (dispense_a == 1'b1);
                end

                begin
                    repeat (30) @(negedge clk);
                    $display("FAIL: Timeout waiting for dispensing");
                    $finish;
                end
            join_any
            disable fork;

            #1;

            if ((expected_product_b && dispense_b && !dispense_a) ||
                (!expected_product_b && dispense_a && !dispense_b)) begin

                if (amount == expected_amount &&
                    change == expected_change) begin
                    $display("PASS: Product %s, amount=%0d, change=%0d",
                        expected_product_b ? "B" : "A",
                        amount, change);
                end else begin
                    $display("FAIL: Expected amount=%0d change=%0d; got amount=%0d change=%0d",
                        expected_amount, expected_change, amount, change);
                end

            end else begin
                $display("FAIL: Incorrect product output");
            end
        end
    endtask

    initial begin
        reset = 1'b1;
        start = 1'b0;
        select_b = 1'b0;
        coin_5 = 1'b0;
        coin_10 = 1'b0;

        $display("--------------------------------");
        $display("VENDING MACHINE TESTBENCH");
        $display("--------------------------------");

        repeat (2) @(negedge clk);
        reset = 1'b0;

        // TEST 1: Product A, exact Rs. 10
        $display("TEST 1: Product A, exact payment");
        start_transaction(1'b0);
        insert_coin10;
        check_result(1'b0, 8'd10, 8'd0);

        wait (busy == 1'b0);
        reset_fsm;

        // TEST 2: Product B, exact Rs. 20
        $display("TEST 2: Product B, exact payment");
        start_transaction(1'b1);
        insert_coin10;
        insert_coin10;
        check_result(1'b1, 8'd20, 8'd0);

        wait (busy == 1'b0);
        reset_fsm;

        // TEST 3: Product A, Rs. 15 payment, Rs. 5 change
        $display("TEST 3: Product A, overpayment");
        start_transaction(1'b0);
        insert_coin10;
        insert_coin5;
        check_result(1'b0, 8'd15, 8'd5);

        wait (busy == 1'b0);
        reset_fsm;

        // TEST 4: Product B, Rs. 25 payment, Rs. 5 change
        $display("TEST 4: Product B, overpayment");
        start_transaction(1'b1);
        insert_coin5;
        insert_coin10;
        insert_coin10;
        check_result(1'b1, 8'd25, 8'd5);

        wait (busy == 1'b0);

        $display("--------------------------------");
        $display("TESTBENCH COMPLETED");
        $display("--------------------------------");
        $finish;
    end

    // Global simulation timeout
    initial begin
        #10000;
        $display("FAIL: Global simulation timeout");
        $finish;
    end

endmodule
