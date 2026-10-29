
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

    vending_fsm #(
        .CLK_FREQ_HZ(3),
        .DISPENSE_SECONDS(1)
    ) dut (
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

    always #5 clk = ~clk;

    task start_transaction;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            @(negedge clk);
        end
    endtask

    task insert_coin5;
        begin
            @(negedge clk);
            coin_5 = 1'b1;
            @(negedge clk);
            coin_5 = 1'b0;
            @(negedge clk);
        end
    endtask

    task insert_coin10;
        begin
            @(negedge clk);
            coin_10 = 1'b1;
            @(negedge clk);
            coin_10 = 1'b0;
            @(negedge clk);
        end
    endtask

    initial begin
        clk      = 1'b0;
        reset    = 1'b1;
        start    = 1'b0;
        select_b = 1'b0;
        coin_5   = 1'b0;
        coin_10  = 1'b0;

        repeat (2) @(negedge clk);
        reset = 1'b0;

        // Test 1: Product A costs 10; insert 5 + 10.
        $display("TEST 1: Product A, insert 5 then 10");

        select_b = 1'b0;
        start_transaction();

        insert_coin5();
        if (amount !== 8'd5)
            $fatal(1, "FAIL: expected amount 5, got %0d", amount);
        $display("PASS: amount = %0d", amount);

        insert_coin10();
        if (amount !== 8'd15)
            $fatal(1, "FAIL: expected amount 15, got %0d", amount);
        if (change !== 8'd5)
            $fatal(1, "FAIL: expected change 5, got %0d", change);
        $display("PASS: amount = %0d, change = %0d", amount, change);

        wait (dispense_a == 1'b1);
        if (change !== 8'd5)
            $fatal(1, "FAIL: Product A change is not 5");
        $display("PASS: Product A dispensed; change = %0d", change);

        wait (busy == 1'b0);
        if (amount !== 8'd0 || change !== 8'd0)
            $fatal(1, "FAIL: transaction did not reset to zero");
        $display("PASS: transaction completed; amount = 0, change = 0");

        // Test 2: Product B costs 20; insert 10 + 10.
        $display("TEST 2: Product B, insert 10 then 10");

        select_b = 1'b1;
        start_transaction();

        insert_coin10();
        if (amount !== 8'd10)
            $fatal(1, "FAIL: expected amount 10, got %0d", amount);

        insert_coin10();
        if (amount !== 8'd20 || change !== 8'd0)
            $fatal(1, "FAIL: expected amount 20 and change 0");
        $display("PASS: Product B total = %0d, change = %0d",
                 amount, change);

        wait (dispense_b == 1'b1);
        $display("PASS: Product B dispensed");

        wait (busy == 1'b0);
        if (amount !== 8'd0 || change !== 8'd0)
            $fatal(1, "FAIL: Product B transaction did not reset");

        $display("ALL TESTS PASSED");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "FAIL: testbench timeout");
    end

endmodule
