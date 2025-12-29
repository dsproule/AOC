`include "common.svh"

module prim_calc(
    input logic clock, reset, cur_base_valid, input_valid,
    input logic [`DATA_WIDTH-1:0] cur_base_in, block_size_in, ub_in,
    input logic [1:0] r,

    output logic prim_sub_out_valid,
    output logic [`LONG_DATA_WIDTH-1:0] prim_sub_out
);
    localparam prim_latency = 4;

    logic prim_en;
    assign prim_en = r < block_size_in && (r == 1 || !(block_size_in & 1'b1)) && cur_base_valid;

    logic rep_base_valid;
    assign rep_base_valid = (k > (block_size_in / r) && cur_base_valid);

    logic [`DATA_WIDTH-1:0] rep_base;
    int unsigned k, k_bound, pow_m;

    assign k_bound = (r == 1) ? block_size_in : block_size_in >> 1;

    always_ff @(posedge clock) begin
        if (reset || !input_valid) begin
            rep_base <= '0;
            k     <= '0;
            pow_m <= '0;
        end else if (k <= k_bound && cur_base_valid) begin
            k <= k + 1;
            pow_m <= pow10(k * r);
            rep_base <= pow_m + rep_base;
        end
    end

    logic [`DATA_WIDTH-1:0] lb_r_next, ub_r_next, lb_r, ub_r;
    logic [`DATA_WIDTH-1:0] S_next, N_next, BM_next, M_next, S, N, BM, M;
    logic [`LONG_DATA_WIDTH-1:0] PS_next, PS;

    always_comb begin
        lb_r_next = (r == 1) ? 1 : pow10(r - 1);
        ub_r_next = ub_in / rep_base;

        S_next = lb_r + ub_r;
        N_next = ub_r - lb_r + 1;
        M_next = (S * N) >> 1;
        BM_next = cur_base_in * rep_base;

        PS_next = (ub_r >= lb_r) ? BM * M : '0;
    end

    int unsigned prim_sub_cycles;
    always_ff @(posedge clock) begin
        if (reset || !input_valid) begin
            ub_r <= '0;
            lb_r <= '0;

            S  <= '0;
            N  <= '0;
            M  <= '0;
            BM <= '0;

            PS    <= '0;
            prim_sub_cycles <= '0;
        end else if (rep_base_valid) begin
            ub_r <= ub_r_next;
            lb_r <= lb_r_next;

            S <= S_next;
            N <= N_next;
            M <= M_next;
            BM <= BM_next;

            PS <= PS_next;
            if (prim_sub_cycles < prim_latency)
                prim_sub_cycles <= prim_sub_cycles + 1;
        end
    end

    assign prim_sub_out_valid = (prim_sub_cycles == prim_latency) || (~prim_en && cur_base_valid);
    assign prim_sub_out = (prim_en) ? PS : '0;

endmodule