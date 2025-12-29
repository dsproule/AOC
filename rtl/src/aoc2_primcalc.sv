`include "common.svh"

module prim_calc(
    input logic clock, reset, cur_base_valid, input_valid,
    input logic [`DATA_WIDTH-1:0] cur_base_in, block_size_in, ub_in,
    input logic [1:0] r,

    output logic prim_sub_out_valid,
    output logic [`LONG_DATA_WIDTH-1:0] prim_sub_out
);

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

    logic [`DATA_WIDTH-1:0] lb_r, ub_r, lb_r_reg, ub_r_reg;
    logic [`DATA_WIDTH-1:0] S, N, BM, M, S_reg, N_reg, BM_reg, M_reg;
    logic [`LONG_DATA_WIDTH-1:0] PS, PS_reg;

    always_comb begin
        lb_r = (r == 1) ? 1 : pow10(r - 1);
        ub_r = ub_in / rep_base;

        S = lb_r_reg + ub_r_reg;
        N = ub_r_reg - lb_r_reg + 1;
        M = (S_reg * N_reg) >> 1;
        BM = cur_base_in * rep_base;

        PS = (ub_r_reg >= lb_r_reg) ? BM * M : '0;
    end

    int unsigned prim_sub_cycles;
    always_ff @(posedge clock) begin
        if (reset || !input_valid) begin
            ub_r_reg <= '0;
            lb_r_reg <= '0;

            S_reg  <= '0;
            N_reg  <= '0;
            M_reg  <= '0;
            BM_reg <= '0;

            PS_reg    <= PS;
            prim_sub_cycles <= '0;
        end else if (rep_base_valid) begin
            ub_r_reg <= ub_r;
            lb_r_reg <= lb_r;

            S_reg <= S;
            N_reg <= N;
            M_reg <= M;
            BM_reg <= BM;

            PS_reg <= PS;
            if (prim_sub_cycles < 3)
                prim_sub_cycles <= prim_sub_cycles + 1;
        end
    end

    assign prim_sub_out_valid = (prim_sub_cycles == 3) || (~prim_en && cur_base_valid);
    assign prim_sub_out = (prim_en) ? PS_reg : '0;

endmodule