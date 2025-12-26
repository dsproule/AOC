module aoc7_tb;

    localparam LINE_LENGTH = 141;

    logic clock, reset, split_in, en;
    logic [`LONG_DATA_WIDTH-1:0] count_out;

    splitter #(.LINE_LENGTH(LINE_LENGTH)) top (.*);

    task print_regs;
        for (int i = 0; i < LINE_LENGTH; i++)
            $write("%0b", top.data[i] != 0);
        $display("");
    endtask

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc7_tb);
    end

    int fd;
    int c;
    int done;
    longint cum_sum = 0;
    
    logic newline;

    initial begin
        fd = $fopen("input7.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input7.txt");
        clock = 1'b0;
        reset = 1;
        done  = 1'b0;
        split_in = 1'b0;
        en = 1'b0;
        newline = 1'b0;
        repeat (3) @(negedge clock);
        reset = 1'b0;
        @(negedge clock);

        @(negedge clock);
        while (!done) begin
            c = $fgetc(fd);
            newline = 1'b0;

            if (c == -1) begin
                done = 1;
            end
            else if (c == 10) begin
                newline = 1'b1;
                @(negedge clock);
                en = 1'b0;
                // print_regs;
            end
            else begin
                @(negedge clock);
                en = 1;
                split_in = (c == "^");
            end
        end
        en = 1'b0;
        for (int i = 0; i < LINE_LENGTH; i++) begin
            en = 1'b1;
            cum_sum = cum_sum + count_out;
            @(negedge clock);
        end

        $display("Answer is: %0d", cum_sum);
        $display("Correct: %0b", cum_sum == 5921061943075);
        $finish;
    end 
endmodule