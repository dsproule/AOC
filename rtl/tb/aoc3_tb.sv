`include "common.svh"

module aoc3_tb;

    localparam MAX_CAP = 4;

    logic clock, reset, data_in_valid, full, empty, data_out_valid, newline;
    logic [`DATA_WIDTH-1:0] data_in, data_out, nums_left;
    logic [$clog2(MAX_CAP):0] size;

    top #(.line_length(15)) dut (.*);

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

    initial begin
        fd = $fopen("input3.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input3.txt");

        clock = 0;
        reset = 1;
        data_in_valid = 1'b0;
        nums_left = 8;
        repeat (3) @(negedge clock);
        reset = 0;
        @(negedge clock);
        data_in_valid = 1'b1;
        data_in = `DATA_WIDTH'd30;
        

        $fclose(fd);
        $finish;
    end

endmodule
