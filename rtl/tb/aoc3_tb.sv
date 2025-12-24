`include "common.svh"

module aoc3_tb;

    localparam MAX_CAP = 4;

    logic clock, reset, data_in_valid, full, empty;
    logic [`DATA_WIDTH-1:0] data_in;
    logic [$clog2(MAX_CAP):0] size;

    long_stack #(.MAX_CAP(MAX_CAP)) stack (.*);

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
        fd = $fopen("input1.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input1.txt");

        clock = 0;
        reset = 1;
        data_in_valid = 1'b0;
        repeat (3) @(negedge clock);
        reset = 0;
        @(negedge clock);
        data_in_valid = 1'b1;
        data_in = `DATA_WIDTH'(30);
        @(negedge clock);
        data_in_valid = 1'b1;
        data_in = `DATA_WIDTH'(27);
        @(negedge clock);
        data_in_valid = 1'b1;
        data_in = `DATA_WIDTH'(24);
        @(negedge clock);
        data_in_valid = 1'b1;
        data_in = `DATA_WIDTH'(20);
        @(negedge clock);
        data_in_valid = 1'b1;
        data_in = `DATA_WIDTH'(16);
        repeat (3) @(negedge clock);

        $fclose(fd);
        $finish;
    end

endmodule
