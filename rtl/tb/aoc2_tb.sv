module aoc2_tb;

    logic clock, reset;
    logic [`DATA_WIDTH-1:0] data_in, digs_out;

    get_digs dut(.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc2_tb);
    end

    initial begin
        clock = 0;
        repeat (3) @(negedge clock);
        data_in = 99; #1;
        assert(digs_out == 2);
        @(negedge clock);
        data_in = 100; #1;
        assert(digs_out == 3);
        @(negedge clock);
        data_in = 0; #1;
        assert(digs_out == 1);
        @(negedge clock);
        data_in = 1; #1;
        assert(digs_out == 1);
        @(negedge clock);
        data_in = 1021430; #1;
        assert(digs_out == 7);
        @(negedge clock);
        data_in = 21234; #1;
        assert(digs_out == 5);
        @(negedge clock);

        $finish;
    end 
endmodule