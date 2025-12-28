`include "common.svh"

module get_digs(
    input logic [`DATA_WIDTH-1:0] n_in,

    output logic [3:0] digs_out
);

    genvar i;
    always_comb begin
        digs_out = 1;
        for (int i = 10; i > 0; i--) begin
            if (n_in < pow10(i))
                digs_out = i;
        end
    end

endmodule

module pref_lookup(
    input logic [3:0] idx,  // 0-10 needs 4 bits

    output logic [`LONG_DATA_WIDTH-1:0] value
);

    always_comb begin
        case (idx)
            4'd0:  value = 64'd0;
            4'd1:  value = 64'd0;
            4'd2:  value = 64'd495;
            4'd3:  value = 64'd5490;
            4'd4:  value = 64'd500895;
            4'd5:  value = 64'd1000890;
            4'd6:  value = 64'd540590850;
            4'd7:  value = 64'd590590845;
            4'd8:  value = 64'd495095086350;
            4'd9:  value = 64'd990140130900;
            4'd10: value = 64'd496436044631310;
            default: value = 64'd0;
        endcase
    end

endmodule

module group_count #(
    parameter group_count_n = 2
)(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] n_in, 
    input logic [3:0] n_digs_in,

    output logic group_count_out_valid,
    output logic [`LONG_DATA_WIDTH-1:0] group_count_out
);

    logic group_en;
    assign group_en = (n_digs_in % group_count_n) == '0;

    logic [`DATA_WIDTH-1:0] block_size;
    assign block_size = n_digs_in / group_count_n;

    logic cur_base_valid;
    assign cur_base_valid = (k > group_count_n);

    logic [`DATA_WIDTH-1:0] cur_base;
    int unsigned k, pow_m;
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

    int unsigned tmp_sum_cycles;
    logic tmp_sum_valid;

    always_ff @(posedge clock) begin
        if (reset) begin
            S_reg   <= '0;
            N_reg   <= '0;
            M_reg   <= '0;
            tmp_sum <= '0;
            tmp_sum_cycles <= '0;
        end else if (cur_base_valid) begin
            S_reg   <= S;
            N_reg   <= N;
            M_reg   <= M;
            tmp_sum_reg <= tmp_sum;
            
            if (tmp_sum_cycles < 4)
                tmp_sum_cycles <= tmp_sum_cycles + 1;
        end
    end
    
    assign tmp_sum_valid = (tmp_sum_cycles == 4);

    logic [`LONG_DATA_WIDTH-1:0] prim_sub_out_1, prim_sub_out_2;
    logic prim_sub_out_1_valid, prim_sub_out_2_valid;
    prim_calc #(.r(1)) prim_calc_1 (
        .clock(clock), .reset(reset), .cur_base_valid(cur_base_valid),
        .cur_base_in(cur_base), .block_size_in(block_size),
        .ub_in(ub),

        .prim_sub_out_valid(prim_sub_out_1_valid),
        .prim_sub_out(prim_sub_out_1)
    );
    
    prim_calc #(.r(2)) prim_calc_2 (
        .cur_base_in(cur_base), .block_size_in(block_size),
        .ub_in(ub),

        .prim_sub_out_valid(prim_sub_out_2_valid),
        .prim_sub_out(prim_sub_out_2)
    );

    assign group_count_out = (group_en) ? tmp_sum_reg - prim_sub_out_1 - prim_sub_out_2 : '0;
    assign group_count_out_valid = tmp_sum_valid & prim_sub_out_1_valid & prim_sub_out_2_valid;

endmodule

module prim_calc #(
    parameter r = 1
)(
    input logic clock, reset, cur_base_valid,
    input logic [`DATA_WIDTH-1:0] cur_base_in, block_size_in, ub_in,

    output logic prim_sub_out_valid,
    output logic [`LONG_DATA_WIDTH-1:0] prim_sub_out
);

    logic prim_en;
    assign prim_en = (block_size_in % r == '0) && r < block_size_in;

    logic rep_base_valid;
    assign rep_base_valid = (k > (block_size_in / r) && cur_base_valid);
    logic [`DATA_WIDTH-1:0] rep_base;
    int unsigned k, pow_m;
    always_ff @(posedge clock) begin
        if (reset) begin
            rep_base <= '0;
            k     <= '0;
            pow_m <= '0;
        end else if (k <= (block_size_in / r) && cur_base_valid) begin
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
        if (reset) begin
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

    assign prim_sub_out_valid = (prim_sub_cycles == 3) || ~prim_en;
    assign prim_sub_out = (prim_en) ? PS_reg : '0;

endmodule