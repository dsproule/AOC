`include "common.svh"

module aoc1_tb;

    logic clock, reset, en;
    DIR_T dir;
    logic [`DATA_WIDTH-1:0] rot, zeros;

    lock_over_zero dut(.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc1_tb);
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
        en = 0;
        repeat (3) @(negedge clock);
        reset = 0;

        done = 0;
        while (!done) begin
            // Read first character
            cmd = $fgetc(fd);

            if (cmd == -1) done = 1;
            else if (cmd == 10) ;
            else begin
                // Parse integer after command
                value = 0;
                c = $fgetc(fd);

                while (c >= "0" && c <= "9") begin
                    value = value * 10 + (c - "0");
                    c = $fgetc(fd);
                end

                while (c != 10 && c != -1) c = $fgetc(fd);

                dir = (cmd == "L") ? LEFT : RIGHT;
                rot = value;
                en = 1'b1;
                @(negedge clock);
            end
        end
        en = 1'b0;
        $display("Code is: %0d", zeros);

        $fclose(fd);
        $finish;
    end

endmodule
