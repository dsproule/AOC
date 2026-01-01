`include "common.svh"

typedef enum logic {LEFT=1, RIGHT=0} DIR_T;

module lock_over_zero(
    input logic clock, reset, en,
    input DIR_T dir,
    input logic [`DATA_WIDTH-1:0] rot,

    output logic [`DATA_WIDTH-1:0] zeros
);

    localparam int lock_max   = 100;
    localparam int lock_start = 50;

    logic [`DATA_WIDTH-1:0] zeros_inc, rot_mod;
    logic [`DATA_WIDTH-1:0] cur_pos, next_pos, full_rots;

    assign full_rots = (rot * 16'd655) >> 16;       //  (rot / lock_max)
    assign rot_mod = rot - (full_rots * lock_max);  //   rot % lock_max

    always_comb begin
        zeros_inc = full_rots;
        if (dir == LEFT) begin
            
            if (rot_mod > cur_pos) begin
                zeros_inc = full_rots + (cur_pos != '0);
                next_pos = lock_max + (cur_pos - rot_mod);
            end else next_pos = cur_pos - rot_mod;

        end else begin
            
            if (cur_pos + rot_mod > lock_max)
                zeros_inc = full_rots + `DATA_WIDTH'(1);
            next_pos = (cur_pos + rot_mod) % lock_max;

        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            zeros    <= '0;
            cur_pos  <= lock_start;
        end else if (en) begin
            cur_pos <= next_pos;
            zeros   <= zeros + (next_pos == '0) + zeros_inc;
        end
    end

endmodule