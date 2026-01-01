`include "common.svh"

module count_combs(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] n_in,

    output logic count_out_valid,
    output logic [`DATA_WIDTH-1:0] count_out
);

    logic [3:0] digs_out;
    get_digs get_digs_0 (
        .n_in(n_in),

        .digs_out(digs_out)
    );

    logic [`DATA_WIDTH-1:0] gc_outs [10:2];
    logic [10:2] gc_valid; 

    genvar i;
    generate for (i = 2; i < 11; i++) begin
        group_count #(.group_count_n(4'(i))) gc (
            .clock(clock), .reset(reset),
            .n_in(n_in), .n_digs_in(digs_out),

            .group_count_out_valid(gc_valid[i]),
            .group_count_out(gc_outs[i])
        );
    end endgenerate

    logic [`DATA_WIDTH-1:0] stage1 [5];
    logic [`DATA_WIDTH-1:0] stage2 [3];
    logic [`DATA_WIDTH-1:0] stage3 [2];
    logic [`DATA_WIDTH-1:0] stage4;
    
    // Stage 1: Pair up inputs (4 cycles)
    always_ff @(posedge clock) begin
        if (reset) begin
            stage1[0] <= '0;
            stage1[1] <= '0;
            stage1[2] <= '0;
            stage1[3] <= '0;
            stage1[4] <= '0;
        end else begin
            stage1[0] <= gc_outs[2] + gc_outs[3];
            stage1[1] <= gc_outs[4] + gc_outs[5];
            stage1[2] <= gc_outs[6] + gc_outs[7];
            stage1[3] <= gc_outs[8] + gc_outs[9];
            stage1[4] <= gc_outs[10];
        end
    end
    
    // Stage 2: Add pairs (3 cycles)
    always_ff @(posedge clock) begin
        if (reset) begin
            stage2[0] <= '0;
            stage2[1] <= '0;
            stage2[2] <= '0;
        end else begin
            stage2[0] <= stage1[0] + stage1[1];
            stage2[1] <= stage1[2] + stage1[3];
            stage2[2] <= stage1[4];
        end
    end
    
    // Stage 3: Add pairs (2 cycles)
    always_ff @(posedge clock) begin
        if (reset) begin
            stage3[0] <= '0;
            stage3[1] <= '0;
        end else begin
            stage3[0] <= stage2[0] + stage2[1];
            stage3[1] <= stage2[2];
        end
    end
    
    // Stage 4: Final sum
    always_ff @(posedge clock) begin
        if (reset) begin
            stage4 <= '0;
        end else begin
            stage4 <= stage3[0] + stage3[1];
        end
    end
    
    int stage_count;
    always_ff @(posedge clock) begin
        if (reset) begin
            stage_count <= '0;
        end else if (&gc_valid && stage_count < 4) begin
            stage_count <= stage_count + 1;
        end
    end

    assign count_out = stage4 + pref_out;
    assign count_out_valid = (stage_count >= 4);

    logic [`DATA_WIDTH-1:0] pref_out;
    pref_lookup pref (
        .idx(digs_out - 4'(1)),

        .value(pref_out)
    );

endmodule