module aoc2_tb;

    logic clock, reset, count_out_valid;
    logic [`DATA_WIDTH-1:0] n_in, digs_out, n_digs_in;
    logic [`LONG_DATA_WIDTH-1:0] count_out;
    longint unsigned cum_sum, tmp_sum;

    count_combs dut (.*);

    task load_bounds(input longint unsigned end_bound, input longint unsigned start_bound);
        n_in = end_bound;
        @(posedge count_out_valid);
        @(negedge clock);
        end_count = count_out;
        @(negedge clock);
        reset = 1;
        repeat (3) @(negedge clock);
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

    int fd;
    int c;
    int done;

    longint unsigned end_count, start_count, total_sum;
    logic num_i;
    longint unsigned nums [1:0];
    initial begin
        fd = $fopen("input2.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input7.txt");

        clock = 0;
        reset = 1;
        total_sum = '0;
        done = 0;
        
        num_i = 0;
        nums[0] = '0;
        nums[1] = '0;
        
        repeat (3) @(negedge clock);
        reset = 0;
        @(negedge clock);
        while (!done) begin
            c = $fgetc(fd);

            if (c == "," || c == 10 || c == -1) begin
                reset = 0;
                done = (c == -1);
                load_bounds(nums[1], nums[0]);
                cum_sum = cum_sum + tmp_sum;
                #1;
                num_i = 0;
                nums[0] = '0;
                nums[1] = '0;
            end
            else if (c == "-") num_i = ~num_i;
            else begin 
                reset = 1;
                nums[num_i] = nums[num_i] * 10 + c - "0";
            end
        end
        @(negedge clock);
        
        $display("Id sum is: %0d", cum_sum);
        $display("Correct: %0b", cum_sum == 49046150754);
        $fclose(fd);
        $finish;
    end 
endmodule