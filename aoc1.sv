`define DATA_WIDTH 24

typedef enum logic {LEFT=1, RIGHT=0} DIR_T;

module lock_over_zero(
    input logic clock, reset, en,
    input DIR_T dir,
    input logic [`DATA_WIDTH-1:0] rot,

    output logic [`DATA_WIDTH-1:0] zeros
);

    localparam int LOCK_MAX   = 100;
    localparam int LOCK_START = 50;

    logic [`DATA_WIDTH-1:0] zeros_inc, rot_mod;
    logic [`DATA_WIDTH-1:0] cur_pos, next_pos, full_rots;

    assign full_rots = (rot * 16'd655) >> 16;   //  (rot / LOCK_MAX)
    assign rot_mod = rot - (full_rots * LOCK_MAX);

    always_comb begin
        zeros_inc = full_rots;
        if (dir == LEFT) begin
            
            if (rot_mod > cur_pos) begin
                zeros_inc = full_rots + (cur_pos != '0);
                next_pos = LOCK_MAX + (cur_pos - rot_mod);
            end else next_pos = cur_pos - rot_mod;

        end else begin
            
            if (cur_pos + rot_mod > LOCK_MAX)
                zeros_inc = full_rots + `DATA_WIDTH'(1);
            next_pos = (cur_pos + rot_mod) % LOCK_MAX;

        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            zeros    <= '0;
            cur_pos  <= LOCK_START;
        end else if (en) begin
            cur_pos <= next_pos;
            zeros   <= zeros + (next_pos == '0) + zeros_inc;
        end
    end

endmodule

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
