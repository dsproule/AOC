`include "common.svh"

module aoc3_tb;

    localparam MAX_CAP = 12;

    logic clock, reset;
    logic data_in_valid, full, empty, data_out_valid, newline;
    logic [`DATA_WIDTH-1:0] data_in;
    logic [(`DATA_WIDTH * 2)-1:0] data_out, cum_sum = 0;

    top #(.line_length(100)) dut (.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc3_tb);
    end

    int fd;
    int c;
    int cmd;
    int value;
    int done;
    
    task line_done;
        @(negedge clock);
        newline = 1;
        data_in_valid = 1'b0;
        
        repeat (12) @(negedge clock);
        @(negedge clock);
        reset = 1;
        
        @(negedge clock);
        newline = 0;
        reset = 0;
    endtask

    task print_stack;
        for (int stack_i = 0; stack_i < dut.stack.sp; stack_i++)
            $write("%0d", dut.stack.data[stack_i]);
    endtask

    always_ff @(posedge clock) begin
        if (data_out_valid & ~reset) begin
            cum_sum <= cum_sum + data_out;
        end
    end

    initial begin
        fd = $fopen("input3.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input3.txt");

        clock   = 0;
        reset   = 1;
        newline = 1'b0;
        data_in_valid = 1'b0;
        repeat (3) @(negedge clock);
        reset   = 0;
        done    = 0;
        cum_sum = 0;

        @(negedge clock);
        while (!done) begin
            c = $fgetc(fd);

            if (c == -1) begin
                done = 1;
            end
            else if (c == 10) begin
                // newline — do nothing
                line_done;
            end
            else begin
                data_in = c - "0";
                data_in_valid = 1'b1;
            end
            @(negedge clock);
        end
        

        $display("Answer is: %0d", cum_sum);
        $display("Correct: %0b", cum_sum == 167523425665348);
        $fclose(fd);
        $finish;
    end

endmodule
