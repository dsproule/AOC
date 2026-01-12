`include "common.svh"

module count_combs(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] n_in,

    output logic count_out_valid,
    output logic [`DATA_WIDTH-1:0] count_out
);
    localparam max_digs = 10;

    logic [3:0] digs_out;
    get_digs get_digs_0 (
        .n_in(n_in),

        .digs_out(digs_out)
    );

    logic [`DATA_WIDTH-1:0] gc_outs [10:2];
    logic [10:2] gc_valid; 

    // instantiations of the divisor chunks
    genvar i;
    generate for (i = 2; i < max_digs + 1; i++) begin
        group_count #(.group_count_n(4'(i))) gc (
            .clock(clock), .reset(reset),
            .n_in(n_in), .n_digs_in(digs_out),

            .group_count_out_valid(gc_valid[i]),
            .group_count_out(gc_outs[i])
        );
    end endgenerate

    logic [`DATA_WIDTH-1:0] final_sum;
    int stage_i;

    // sums the values at the end (extra 10 cycles insignificant at end of computation)
    always_ff @(posedge clock) begin
        if (reset) begin
            stage_i <= 2;
            final_sum <= '0;
        end else if (&gc_valid && stage_i < max_digs + 1) begin
            final_sum <= final_sum + gc_outs[stage_i];
            stage_i <= stage_i + 1;
        end
    end

    assign count_out = final_sum + pref_out;
    assign count_out_valid = (stage_i >= max_digs + 1);

    logic [`DATA_WIDTH-1:0] pref_out;
    pref_lookup pref (
        .idx(digs_out - 4'(1)),

        .value(pref_out)
    );

endmodule