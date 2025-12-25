module aoc7_tb;

    localparam LINE_LENGTH = 141;

    logic clock, reset, split_in, en;
    logic [`DATA_WIDTH-1:0] count_out;

    splitter #(.LINE_LENGTH(LINE_LENGTH)) top(.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc7_tb);
    end

    int fd;
    int c;
    int done;
    longint cum_sum = 0;

    initial begin
        fd = $fopen("input7.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input7.txt");
        clock = 0;
        reset = 1;
        done  = 0;
        repeat (3) @(negedge clock);
        reset = 0;
        @(negedge clock);

        @(negedge clock);
        while (!done) begin
            c = $fgetc(fd);

            if (c == -1) begin
                done = 1;
            end
            else if (c == 10) begin
                // newline — do nothing
                // line_done;
            end
            else begin
                en = 1;
                split_in = (c == "^");
                // data_in_valid = 1'b1;
            end
            @(negedge clock);
        end
        en = 0;
        for (int i = 0; i < LINE_LENGTH; i++) begin
            cum_sum = cum_sum + count_out;
            @(negedge clock);
        end

        $display("Answer is: %0d", cum_sum);
        $display("Correct: %0b", cum_sum == 5921061943075);
        $finish;
    end 
endmodule