`include "common.svh"

module group_count #(
    parameter group_count_n = 2
)(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] n_in, n_digs_in,

    output logic [`LONG_DATA_WIDTH-1:0] count_out
);

    logic group_en;
    assign group_en = (n_digs_in % group_count_n) == '0;

    logic [`DATA_WIDTH-1:0] block_size;
    assign block_size = n_digs_in / group_count_n;

    logic [`DATA_WIDTH-1:0] cur_base;
    int unsigned k, pow_m;

    // logic stall;
    always_ff @(posedge clock) begin
        if (reset) begin
            cur_base <= '0;
            k     <= '0;
            pow_m <= '0;
        end else if (k <= group_count_n) begin
            k <= k + 1;
            pow_m <= pow10(k * block_size);
            cur_base <= pow_m + cur_base;
        end
    end

    logic [`DATA_WIDTH-1:0] lb, ub_cand_0, ub_cand_1, ub, lb_reg, ub_reg;
    always_comb begin
        lb = (block_size == 1) ? 1 : pow10(block_size - 1);
        
        ub_cand_0 = pow10(block_size) - 1;
        ub_cand_1 = n_in / cur_base;

        ub = (ub_cand_0 < ub_cand_1) ? ub_cand_0 : ub_cand_1;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            lb_reg <= '0;
            ub_reg <= '0;
        end else begin
            lb_reg <= lb;
            ub_reg <= ub;
        end
    end

    logic [`DATA_WIDTH-1:0] S, N, M, S_reg, N_reg, M_reg;
    logic [`LONG_DATA_WIDTH-1:0] tmp_sum, tmp_sum_reg;

    always_comb begin
        S = lb_reg + ub_reg;
        N = ub_reg - lb_reg + 1;
        M = (S_reg * N_reg) >> 1;
        tmp_sum = cur_base * M_reg;
    end

    int tmp_sum_cycles;
    logic tmp_sum_ready;
    assign tmp_sum_ready = (tmp_sum_cycles == 7);

    always_ff @(posedge clock) begin
        if (reset) begin
            S_reg   <= '0;
            N_reg   <= '0;
            M_reg   <= '0;
            tmp_sum <= '0;
            tmp_sum_cycles <= '0;
        end else begin
            S_reg   <= S;
            N_reg   <= N;
            M_reg   <= M;
            tmp_sum_reg <= tmp_sum;
            
            if (tmp_sum_cycles < 7)
                tmp_sum_cycles <= tmp_sum_cycles + 1;
        end
    end

    // logic [`LONG_DATA_WIDTH-1:0] prim_sub_out_1, prim_sub_out_2;
    // prim_calc #(.r(1)) prim_calc_1 (
    //     .cur_base_in(cur_base), .block_size_in(block_size),
    //     .ub_in(ub),

    //     .prim_sub_out(prim_sub_out_1)
    // );
    
    // prim_calc #(.r(2)) prim_calc_2 (
    //     .cur_base_in(cur_base), .block_size_in(block_size),
    //     .ub_in(ub),

    //     .prim_sub_out(prim_sub_out_2)
    // );

    // assign count_out = (group_en) ? tmp_sum_reg - prim_sub_out_1 - prim_sub_out_2 : '0;

endmodule

module prim_calc #(
    parameter r = 1
)(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] cur_base_in, block_size_in, ub_in,

    output logic [`LONG_DATA_WIDTH-1:0] prim_sub_out
);

    logic prim_en;
    assign prim_en = (block_size_in % r == '0) && r < block_size_in;

    logic [`DATA_WIDTH-1:0] rep_base;
    int unsigned k, pow_m;
    always_ff @(posedge clock) begin
        if (reset) begin
            rep_base <= '0;
            k        <=  1;
            pow_m    <= '0;
        end else if (k < (block_size_in / r)) begin
            k     <= k + 1;
            pow_m <= k * r;
            rep_base <= rep_base + pow10(pow_m);
        end
    end

    logic [`DATA_WIDTH-1:0] lb_r, ub_r, lb_r_reg, ub_r_reg;
    logic [`DATA_WIDTH-1:0] S, N, BM, M, S_reg, N_reg, BM_reg, M_reg;
    logic [`LONG_DATA_WIDTH-1:0] PS;

    always_comb begin
        lb_r = (r == 1) ? 1 : pow10(r - 1);
        ub_r = ub_in / rep_base[`DATA_WIDTH-1:0];

        S = lb_r_reg + ub_r_reg;
        N = ub_r_reg - lb_r_reg + 1;
        M = (S_reg * N_reg) >> 1;
        BM = cur_base_in * rep_base;

        PS = (ub_r_reg >= lb_r_reg) ? BM * M : '0;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            ub_r_reg <= '0;
            lb_r_reg <= '0;

            S_reg  <= '0;
            N_reg  <= '0;
            M_reg  <= '0;
            BM_reg <= '0;

            prim_sub_out <= PS;
        end else begin
            ub_r_reg <= ub_r;
            lb_r_reg <= lb_r;

            S_reg <= S;
            N_reg <= N;
            M_reg <= M;
            BM_reg <= BM;

            prim_sub_out <= PS;
        end
    end

endmodule