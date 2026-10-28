
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

    integer test_count;

    // Instantiate the DUT with a short dispensing interval.
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

    // 100 MHz simulation clock: 10 ns period.
    always #5 clk = ~clk;

    // Reset the DUT between independent tests.
    task reset_machine;
        begin
            @(negedge clk);
            reset = 1'b1;
            repeat (2) @(negedge clk);
            reset = 1'b0;
            repeat (3) @(negedge clk);
        end
    endtask

    // Apply one coin input for one clock cycle.
    task insert_coin;
        input integer denomination;
        begin
            @(negedge clk);

            if (denomination == 5) begin
                coin_5  = 1'b1;
                coin_10 = 1'b0;
            end
            else if (denomination == 10) begin
                coin_5  = 1'b0;
                coin_10 = 1'b1;
            end
            else begin
                $fatal(1, "Invalid coin denomination");
            end

            @(negedge clk);
            coin_5  = 1'b0;
            coin_10 = 1'b0;

            // Allow the FSM to process the input.
            @(negedge clk);
        end
    endtask

    // Wait for the dispensing pulse and verify the product.
    task check_dispense;
        input expected_a;
        input expected_b;

        integer cycles;
        reg found;
        begin
            cycles = 0;
            found = 1'b0;

            while ((cycles < 10) && !found) begin
                @(negedge clk);
                cycles = cycles + 1;

                if (dispense_a || dispense_b)
                    found = 1'b1;
            end

            if (!found)
                $fatal(1, "FAIL: Dispensing timeout");

            if (dispense_a !== expected_a ||
                dispense_b !== expected_b)
                $fatal(1, "FAIL: Incorrect product dispensed");

            $display(
                "PASS: Dispense A=%b B=%b, amount=%0d, change=%0d",
                dispense_a, dispense_b, amount, change
            );
        end
    endtask

    initial begin
        clk       = 1'b0;
        reset     = 1'b1;
        select_b  = 1'b0;
        coin_5    = 1'b0;
        coin_10   = 1'b0;
        test_count = 0;

        // Initial reset.
        repeat (3) @(negedge clk);
        reset = 1'b0;
        repeat (3) @(negedge clk);

        // ------------------------------------------------
        // TEST 1: Product A costs Rs. 10.
        // Insert Rs. 5 + Rs. 5.
        // Expected: Product A, Rs. 0 change.
        // ------------------------------------------------
        $display("\nTEST 1: Product A, Rs. 10 payment");

        select_b = 1'b0;
        repeat (2) @(negedge clk);

        insert_coin(5);
        insert_coin(5);

        check_dispense(1'b1, 1'b0);

        if (change !== 8'd0)
            $fatal(1, "FAIL: Unexpected change in Test 1");

        test_count = test_count + 1;

        // ------------------------------------------------
        // TEST 2: Product B costs Rs. 20.
        // Insert Rs. 10 + Rs. 10.
        // Expected: Product B, Rs. 0 change.
        // ------------------------------------------------
        reset_machine();

        $display("\nTEST 2: Product B, Rs. 20 payment");

        select_b = 1'b1;
        repeat (2) @(negedge clk);

        insert_coin(10);
        insert_coin(10);

        check_dispense(1'b0, 1'b1);

        if (change !== 8'd0)
            $fatal(1, "FAIL: Unexpected change in Test 2");

        test_count = test_count + 1;

        // ------------------------------------------------
        // TEST 3: Product B costs Rs. 20.
        // Insert Rs. 10 + Rs. 10 + Rs. 5.
        // Expected: Product B, Rs. 5 change.
        // ------------------------------------------------
        reset_machine();

        $display("\nTEST 3: Product B, Rs. 25 payment");

        select_b = 1'b1;
        repeat (2) @(negedge clk);

        insert_coin(10);
        insert_coin(10);
        insert_coin(5);

        check_dispense(1'b0, 1'b1);

        if (change !== 8'd5)
            $fatal(1, "FAIL: Expected Rs. 5 change");

        test_count = test_count + 1;

        // All tests completed.
        $display("\n--------------------------------");
        $display("Completed %0d transaction tests.", test_count);
        $display("All tests passed.");
        $display("--------------------------------");

        $finish;
    end

endmodule
