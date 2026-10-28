
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

    // Short timing for simulation
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

    // 100 MHz simulation clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Insert one coin for one clock cycle
    task insert_coin5;
        begin
            @(negedge clk);
            coin_5 = 1'b1;
            @(negedge clk);
            coin_5 = 1'b0;
        end
    endtask

    task insert_coin10;
        begin
            @(negedge clk);
            coin_10 = 1'b1;
            @(negedge clk);
            coin_10 = 1'b0;
        end
    endtask

    // Start a transaction after selecting the product
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

    // Reset the FSM between test cases
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

    initial begin
        reset = 1'b1;
        start = 1'b0;
        select_b = 1'b0;
        coin_5 = 1'b0;
        coin_10 = 1'b0;

        $display("Starting vending machine tests");

        // Allow initial reset
        repeat (2) @(negedge clk);
        reset = 1'b0;

        // TEST 1: Product A costs Rs. 10
        $display("TEST 1: Product A, exact payment Rs. 10");
        start_transaction(1'b0);
        insert_coin10;

        wait (dispense_a == 1'b1);
        #1;
        if (amount == 10 && change == 0 && dispense_b == 0)
            $display("PASS: Product A dispensed correctly");
        else
            $display("FAIL: A amount=%0d change=%0d", amount, change);

        wait (busy == 1'b0);
        reset_fsm;

        // TEST 2: Product B costs Rs. 20
        $display("TEST 2: Product B, exact payment Rs. 20");
        start_transaction(1'b1);
        insert_coin10;
        insert_coin10;

        wait (dispense_b == 1'b1);
        #1;
        if (amount == 20 && change == 0 && dispense_a == 0)
            $display("PASS: Product B dispensed correctly");
        else
            $display("FAIL: B amount=%0d change=%0d", amount, change);

        wait (busy == 1'b0);
        reset_fsm;

        // TEST 3: Product B costs Rs. 20; pay Rs. 25
        $display("TEST 3: Product B, payment Rs. 25, change Rs. 5");
        start_transaction(1'b1);
        insert_coin5;
        insert_coin10;
        insert_coin10;

        wait (dispense_b == 1'b1);
        #1;
        if (amount == 25 && change == 5 && dispense_a == 0)
            $display("PASS: Product B and Rs. 5 change");
        else
            $display("FAIL: B amount=%0d change=%0d", amount, change);

        wait (busy == 1'b0);

        $display("All test cases completed");
        $finish;
    end

    // Stop simulation if a test hangs
    initial begin
        #10000;
        $display("ERROR: Simulation timed out");
        $finish;
    end

endmodule
