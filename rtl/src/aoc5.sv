`include "common.svh"

typedef struct packed {
    logic [`DATA_WIDTH-1:0] first;
    logic [`DATA_WIDTH-1:0] second;
} tuple_pair_t;

typedef struct packed {
    tuple_pair_t first;
    tuple_pair_t second;
} swp_tuple_pair_t;

function automatic swp_tuple_pair_t cmp_swp(
    input tuple_pair_t a, b,
    input logic asc
);
    logic swp;
    swp_tuple_pair_t result;

    swp = (a.first > b.first) == asc;

    if (swp) begin
        result.first  = b;
        result.second = a;
    end else begin
        result.first  = a;
        result.second = b;
    end

    cmp_swp = result;

endfunction

module sorter_8 #(
    parameter asc = 1
)(
    input logic clock, reset,
    input logic valid_in, 
    input tuple_pair_t pairs_in [8],
    
    output logic valid_out,
    output tuple_pair_t pairs_out [8]
);
    tuple_pair_t stage1 [8], stage2 [8], stage3 [8];
    tuple_pair_t stage4 [8], stage5 [8];
    logic [7:1] stage_valid;

    // stage 1
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 8; i++)
                stage1[i] <= '0;
            stage_valid[1] <= 1'b0;
        end else begin
            {stage1[0], stage1[2]}  <= cmp_swp(pairs_in[0], pairs_in[2], asc);
            {stage1[1], stage1[3]}  <= cmp_swp(pairs_in[1], pairs_in[3], asc);
            {stage1[4], stage1[6]}  <= cmp_swp(pairs_in[4], pairs_in[6], asc);
            {stage1[5], stage1[7]}  <= cmp_swp(pairs_in[5], pairs_in[7], asc);
            stage_valid[1] <= valid_in;
        end
    end
    
    // stage2
    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         for (int i = 0; i < 8; i++)
    //             stage2[i] <= '0;
    //         stage_valid[2] <= 1'b0;
    //     end else begin
    //         for (int i = 0; i < 4; i++) begin
    //             {stage2[i], stage2[i + 4]} <= cmp_swp(stage1[i], stage1[i + 4], asc);
    //         end
    //     end
    // end
    
    // // stage3
    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         for (int i = 0; i < 8; i++)
    //             stage3[i] <= '0;
    //         stage_valid[3] <= 1'b0;
    //     end else begin
    //         for (int i = 0; i < 8; i = i + 2) begin
    //             {stage3[i], stage3[i + 1]} <= cmp_swp(stage2[i], stage2[i + 1], asc);
    //         end
    //     end
    // end
    
    // // stage4
    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         for (int i = 0; i < 8; i++)
    //             stage4[i] <= '0;
    //         stage_valid[4] <= 1'b0;
    //     end else begin
    //         for (int i = 2; i < 4; i++) begin
    //             {stage4[i], stage4[i + 2]} <= cmp_swp(stage3[i], stage3[i + 2], asc);
    //         end
    //     end
    // end
    
    // // stage5
    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         for (int i = 0; i < 8; i++)
    //             stage5[i] <= '0;
    //         stage_valid[5] <= 1'b0;
    //     end else begin
    //         for (int i = 1; i < 4; i = i + 2) begin
    //             {stage5[i], stage5[i + 3]} <= cmp_swp(stage4[i], stage4[i + 3], asc);
    //         end
    //     end
    // end
    
    // // stage6
    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         for (int i = 0; i < 8; i++)
    //             pairs_out[i] <= '0;
    //         valid_out <= 1'b0;
    //     end else begin
    //         for (int i = 1; i < 7; i = i + 2) begin
    //             {pairs_out[i], pairs_out[i + 1]} <= cmp_swp(stage5[i], stage5[i + 1], asc);
    //         end
    //     end
    // end
    
    
endmodule