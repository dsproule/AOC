module aoc2_tb;

    logic clock, reset;
    logic [`DATA_WIDTH-1:0] n_in, digs_out, n_digs_in;
    logic [`LONG_DATA_WIDTH-1:0] count_out;

    get_digs get_digs_0 (
        .n_in(n_in),

        .digs_out(digs_out)
    );
    
    group_count #(.group_count_n(2)) gc (
        .clock(clock), .reset(reset),
        .n_in(n_in), .n_digs_in(digs_out)
    );

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
        repeat (20) @(negedge clock);

        $finish;
    end 
endmodule