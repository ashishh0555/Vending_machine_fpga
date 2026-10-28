
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

    vending_fsm dut (
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

    // 100 MHz clock
    always #5 clk = ~clk;

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

    task reset_machine;
        begin
            @(negedge clk);
            reset = 1;
            repeat (2) @(negedge clk);
            reset = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    task wait_for_dispense;
        integer cycles;
        begin
            cycles = 0;

            while (!dispense_a && !dispense_b && cycles < 10) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            if (cycles >= 10)
                $fatal(1, "ERROR: Dispense timeout");

            $display("Dispense detected: A=%b B=%b amount=%0d change=%0d",
                     dispense_a, dispense_b, amount, change);
        end
    endtask

    initial begin
        clk      = 0;
        reset    = 1;
        select_b = 0;
        coin_5   = 0;
        coin_10  = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // TEST 1: Product A costs Rs. 10
        repeat (2) @(negedge clk);
        select_b = 0;

        insert_coin(5);
        insert_coin(5);
        wait_for_dispense();

        if (dispense_a !== 1'b1 || change !== 0)
            $fatal(1, "TEST 1 FAILED");

        $display("TEST 1 PASSED");
        reset_machine();

        // TEST 2: Product B costs Rs. 20
        select_b = 1;
        repeat (2) @(negedge clk);

        insert_coin(10);
        insert_coin(10);
        wait_for_dispense();

        if (dispense_b !== 1'b1 || change !== 0)
            $fatal(1, "TEST 2 FAILED");

        $display("TEST 2 PASSED");
        reset_machine();

        // TEST 3: Rs. 25 paid for Product B
        select_b = 1;
        repeat (2) @(negedge clk);

        insert_coin(10);
        insert_coin(10);
        insert_coin(5);
        wait_for_dispense();

        if (dispense_b !== 1'b1 || change !== 5)
            $fatal(1, "TEST 3 FAILED");

        $display("TEST 3 PASSED");
        $display("ALL TESTS PASSED");

        $finish;
    end

endmodule
