module aoc2_tb;

    logic clock, reset, count_out_valid;
    logic [`DATA_WIDTH-1:0] n_in, digs_out, n_digs_in;
    logic [`LONG_DATA_WIDTH-1:0] count_out;
    longint unsigned cum_sum, tmp_sum;

    count_combs dut (.*);

    task load_bounds(input longint unsigned end_bound, input longint unsigned start_bound);
        n_in = end_bound;
        @(posedge count_out_valid);
        end_count = count_out;
        @(negedge clock);
        reset = 1;
        repeat (2) @(negedge clock);
        reset = 0;
        @(negedge clock);

        n_in = start_bound - 1;
        @(posedge count_out_valid);
        start_count = count_out;
        @(negedge clock);
        reset = 1;
        repeat (2) @(negedge clock);
        reset = 0;
        @(negedge clock);

        tmp_sum = end_count - start_count;
    endtask
    
    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc2_tb);
    end

    longint unsigned end_count, start_count, total_sum;
    initial begin
        clock = 0;
        reset = 1;
        total_sum = '0;
        repeat (3) @(negedge clock);
        reset = 0;
        @(negedge clock);
        
        load_bounds(28343, 2843);
        cum_sum = cum_sum + tmp_sum;
        $display("%0d", cum_sum);
        repeat (3) @(negedge clock);
        $finish;
    end 
endmodule