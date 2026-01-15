`include "common.svh"
`include "aoc5.svh"

// arrays flattened in io to allow synthesis
module sorter_8 (
    input logic clock, reset, 
    input logic valid_in, asc_in,
    input logic [`ARR_8_FLAT_WIDTH-1:0] pairs_in_flat,
    
    output logic valid_out, saturated_out,
    output logic [`ARR_8_FLAT_WIDTH-1:0] pairs_out_flat
);
    tuple_pair_t stage_1 [8], stage_2 [8], stage_3 [8];
    tuple_pair_t stage_4 [8], stage_5 [8];
    tuple_pair_t pairs_out_unpack [8], pairs_in_unpack [8];

    logic [6:1] sort_dir, stage_valid;

    always_comb begin
        for (int i = 0; i < 8; i++) 
            pairs_in_unpack[i] = `index_flat(pairs_in_flat, i);
    end

    // implemented diagram of 8 inputs: https://bertdobbelaere.github.io/sorting_networks.html

    // stage 1
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 8; i++)
                stage_1[i] <= '0;
            stage_valid[1] <= 1'b0;
        end else begin
            `pass_through(pairs_in_unpack, stage_1, 8);
            for (int i = 0; i < 6; i = i + 4) begin
                {stage_1[i], stage_1[i + 2]}     <= cmp_swp(pairs_in_unpack[i], pairs_in_unpack[i + 2], asc_in);
                {stage_1[i + 1], stage_1[i + 3]} <= cmp_swp(pairs_in_unpack[i + 1], pairs_in_unpack[i + 3], asc_in);
            end

            sort_dir[1]    <= asc_in;
            stage_valid[1] <= valid_in;
        end
    end
    
    // stage 2
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 8; i++)
                stage_2[i] <= '0;
            stage_valid[2] <= 1'b0;
        end else begin
            `pass_through(stage_1, stage_2, 8);
            for (int i = 0; i < 4; i++)
                {stage_2[i], stage_2[i + 4]} <= cmp_swp(stage_1[i], stage_1[i + 4], sort_dir[1]);

            sort_dir[2]    <= sort_dir[1];
            stage_valid[2] <= stage_valid[1];
        end
    end
    
    // stage 3
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 8; i++)
                stage_3[i] <= '0;
            stage_valid[3] <= 1'b0;
        end else begin
            `pass_through(stage_2, stage_3, 8);
            for (int i = 0; i < 8; i = i + 2)
                {stage_3[i], stage_3[i + 1]} <= cmp_swp(stage_2[i], stage_2[i + 1], sort_dir[2]);

            sort_dir[3]    <= sort_dir[2];
            stage_valid[3] <= stage_valid[2];
        end
    end
    
    // stage 4
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 8; i++)
                stage_4[i] <= '0;
            stage_valid[4] <= 1'b0;
        end else begin
            `pass_through(stage_3, stage_4, 8);
            for (int i = 2; i < 4; i++)
                {stage_4[i], stage_4[i + 2]} <= cmp_swp(stage_3[i], stage_3[i + 2], sort_dir[3]);

            sort_dir[4]    <= sort_dir[3];
            stage_valid[4] <= stage_valid[3];
        end
    end
    
    // stage 5
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 8; i++)
                stage_5[i] <= '0;
            stage_valid[5] <= 1'b0;
        end else begin
            `pass_through(stage_4, stage_5, 8);
            for (int i = 1; i < 4; i = i + 2)
                {stage_5[i], stage_5[i + 3]} <= cmp_swp(stage_4[i], stage_4[i + 3], sort_dir[4]);

            sort_dir[5]    <= sort_dir[4];
            stage_valid[5] <= stage_valid[4];
        end
    end
    
    // stage 6
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 8; i++)
                pairs_out_unpack[i] <= '0;
            stage_valid[6] <= 1'b0;
        end else begin
            `pass_through(stage_5, pairs_out_unpack, 8);
            for (int i = 1; i < 7; i = i + 2)
                {pairs_out_unpack[i], pairs_out_unpack[i + 1]} <= cmp_swp(stage_5[i], stage_5[i + 1], sort_dir[5]);

            stage_valid[6] <= stage_valid[5];
        end
    end

    always_comb begin
        for (int i = 0; i < 8; i++) 
            `index_flat(pairs_out_flat, i) = pairs_out_unpack[i];
    end

    assign saturated_out = &stage_valid;
    assign valid_out = stage_valid[6];
    
endmodule