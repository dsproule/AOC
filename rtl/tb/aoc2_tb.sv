module aoc2_tb;

    logic clock, reset, count_out_valid;
    logic [`DATA_WIDTH-1:0] n_in, digs_out, n_digs_in;
    logic [`LONG_DATA_WIDTH-1:0] count_out;

    count_combs dut (.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc2_tb);
    end

    initial begin
        clock = 0;
        reset = 1;
        repeat (3) @(negedge clock);
        reset = 0;
        @(negedge clock);
        n_in = 2843; #1;
        repeat (30) @(negedge clock);

        $finish;
    end 
endmodule