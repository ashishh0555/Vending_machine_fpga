
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

    // Instantiate the vending machine controller
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

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    // Apply a coin for exactly one clock cycle
    task insert_coin;
        input integer denomination;
        begin
            @(negedge clk);
            if (denomination == 5) begin
                coin_5 = 1;
                coin_10 = 0;
            end
            else if (denomination == 10) begin
                coin_5 = 0;
                coin_10 = 1;
            end

            @(negedge clk);
            coin_5 = 0;
            coin_10 = 0;
            @(negedge clk);
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        select_b = 0;
        coin_5 = 0;
        coin_10 = 0;

        // Reset the controller
        repeat (3) @(negedge clk);
        reset = 0;

        // Allow the controller to enter COLLECT
        repeat (2) @(negedge clk);

        // TEST 1: Product A, price Rs. 10
        $display("TEST 1: Product A - Rs. 5 + Rs. 5");
        select_b = 0;
        insert_coin(5);
        insert_coin(5);
        repeat (3) @(negedge clk);

        if (dispense_a)
            $display("Product A dispensed");
        else
            $display("Observe waveform for dispense pulse");

        // Reset between tests
        reset = 1;
        @(negedge clk);
        reset = 0;
        repeat (2) @(negedge clk);

        // TEST 2: Product B, price Rs. 20
        $display("TEST 2: Product B - Rs. 10 + Rs. 10");
        select_b = 1;
        insert_coin(10);
        insert_coin(10);
        repeat (3) @(negedge clk);

        // Reset between tests
        reset = 1;
        @(negedge clk);
        reset = 0;
        repeat (2) @(negedge clk);

        // TEST 3: Product B, Rs. 10 + Rs. 10 + Rs. 5
        $display("TEST 3: Product B - Rs. 25, expected Rs. 5 change");
        select_b = 1;
        insert_coin(10);
        insert_coin(10);
        insert_coin(5);
        repeat (3) @(negedge clk);

        $display("Simulation completed.");
        $finish;
    end

endmodule
