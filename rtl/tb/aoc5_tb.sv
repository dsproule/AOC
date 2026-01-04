module aoc5_tb;

    logic clock, reset;

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc5_tb);
    end

    initial begin
        clock = 0;
        reset = 1;

        repeat (3) @(negedge clock);
        reset = 0;
        @(negedge clock);

        $finish;
    end

endmodule