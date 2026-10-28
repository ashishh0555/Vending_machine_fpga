
`timescale 1ns / 1ps

module vending_machine_tb;

    reg clk;
    reg reset;
    reg select_b;
    reg coin_5;
    reg coin_10;

    wire dispense_a;
    wire dispense_b;
    wire [7:0] amount;
    wire [7:0] change;

    integer passed;

    // Short display interval for simulation.
    vending_fsm #(
        .DISPENSE_CYCLES(5)
    ) dut (
        .clk(clk),
        .reset(reset),
        .select_b(select_b),
        .coin_5(coin_5),
        .coin_10(coin_10),
        .dispense_a(dispense_a),
        .dispense_b(dispense_b),
        .amount(amount),
        .change(change)
    );

    // 100 MHz simulation clock
    always #5 clk = ~clk;

    task reset_machine;
        begin
            @(negedge clk);
            reset = 1;
            repeat (2) @(negedge clk);
            reset = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    task insert_coin;
        input integer denomination;
        begin
            @(negedge clk);
            coin_5  = (denomination == 5);
            coin_10 = (denomination == 10);

            @(negedge clk);
            coin_5  = 0;
            coin_10 = 0;

            @(negedge clk);
        end
    endtask

    task check_transaction;
        input expected_a;
        input expected_b;
        input [7:0] expected_change;

        integer timeout;
        reg found;
        begin
            timeout = 0;
            found = 0;

            while (!found && timeout < 10) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;

                if (dispense_a || dispense_b)
                    found = 1;
            end

            if (!found)
                $fatal(1, "FAIL: Dispense timeout");

            if (dispense_a !== expected_a ||
                dispense_b !== expected_b)
                $fatal(1, "FAIL: Wrong product dispensed");

            if (change !== expected_change)
                $fatal(1, "FAIL: Incorrect change");

            $display(
                "PASS: A=%b B=%b amount=%0d change=%0d",
                dispense_a, dispense_b, amount, change
            );
            passed = passed + 1;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        select_b = 0;
        coin_5 = 0;
        coin_10 = 0;
        passed = 0;

        repeat (3) @(negedge clk);
        reset = 0;
        repeat (2) @(negedge clk);

        // Test 1: Product A, Rs. 10 paid
        $display("TEST 1: Product A");
        select_b = 0;
        repeat (2) @(negedge clk);
        insert_coin(5);
        insert_coin(5);
        check_transaction(1'b1, 1'b0, 8'd0);

        reset_machine();

        // Test 2: Product B, Rs. 20 paid
        $display("TEST 2: Product B");
        select_b = 1;
        repeat (2) @(negedge clk);
        insert_coin(10);
        insert_coin(10);
        check_transaction(1'b0, 1'b1, 8'd0);

        reset_machine();

        // Test 3: Product B, Rs. 25 paid
        $display("TEST 3: Change return");
        select_b = 1;
        repeat (2) @(negedge clk);
        insert_coin(10);
        insert_coin(10);
        insert_coin(5);
        check_transaction(1'b0, 1'b1, 8'd5);

        $display("Tests passed: %0d / 3", passed);
        $display("Simulation completed.");
        $finish;
    end

endmodule
