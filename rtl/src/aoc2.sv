`include "common.svh"

`define MAX_DIGS 10

module group_count #(
    parameter group_count_n = 2
)(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] data_in, n_digs_in
);

    logic block_en;
    assign block_en = ((n_digs_in % group_count_n) == '0);

    logic [$clog2(group_count_n)-1:0] block_size;
    assign block_size = n_digs_in / group_count_n;

    logic [`DATA_WIDTH-1:0] cur_base;
    logic [$clog2(group_count_n):0] k;
    logic cur_base_ready;
    
    assign cur_base_ready = (k != group_count_n);

    // # 10 ^ (block_size * k) for k in group_count -> base to rebuild number
    always_ff @(posedge clock) begin
        if (reset) begin
            cur_base <= '0;
            k        <= '0;
        end else if (!cur_base_ready) begin
            cur_base <= pow10(k * block_size) + cur_base;
            k        <= k + 1;
        end
    end

    logic [`DATA_WIDTH-1:0] lb, lb_reg;
    logic [`DATA_WIDTH-1:0] ub_cand0, ub_cand1, ub, ub_reg;

    // # series of all possible nums
    always_comb begin
        lb = (block_size == 1) ? 1 : pow10(block_size - 1);

        ub_cand0 = pow10(block_size) - 1;
        ub_cand1 = data_in / cur_base;    // can be multi-cycle
        
        // min value
        ub = (ub_cand0 < ub_cand1 && cur_base_ready) ? ub_cand0 : ub_cand1;
    end 

    logic bounds_ready;
    always_ff @(posedge clock) begin
        bounds_ready <= ~reset;
        ub_reg <= ub;
        lb_reg <= lb;
    end

    // calculation broken into FSM for simpler timing
    typedef enum logic [1:0] {CALC_S_N, MUL_S_N, CUR_BASE_MUL, DONE} tmp_sum_t;
    
    tmp_sum_t tmp_sum_state, next_tmp_sum_state;
    logic [`DATA_WIDTH-1:0] S, N, tmp_sum, S_reg, N_reg,tmp_sum_reg;
    logic [`LONG_DATA_WIDTH-1:0] S_N, S_N_reg;
    
    // tmp_sum = cur_base * ((lb + ub) * (ub - lb + 1) // 2)
    always_comb begin
        S = S_reg;
        N = N_reg;
        next_tmp_sum_state = tmp_sum_state;

        case (tmp_sum_state)
            CALC_S_N: begin
                // S = (lb + ub), N = (ub - lb + 1)
                S = lb_reg + ub_reg;
                N = ub_reg - lb_reg + 1;
                if (bounds_ready)
                    next_tmp_sum_state = MUL_S_N;
            end
            MUL_S_N: begin
                // N =  (S * N) / 2
                S_N = (S_reg *  N_reg) >> 1;
                next_tmp_sum_state = CUR_BASE_MUL;
            end
            CUR_BASE_MUL: begin
                // cur_base * N
                tmp_sum = cur_base * S_N;
                if (cur_base_ready) 
                    next_tmp_sum_state = DONE;
            end
            default: ;
        endcase
    end

    always_ff @(posedge clock) begin
        tmp_sum_state <= (reset) ? CALC_S_N : next_tmp_sum_state;
        S_reg         <= S;
        N_reg         <= N;
        S_N_reg       <= S_N;
    end

endmodule

module prim_count #(
    parameter r = 2,
    parameter group_count_n = 2
)(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] data_in, n_digs_in, ub, cur_base,

    output logic [`DATA_WIDTH-1:0] prim_sub_out
);

    logic [`DATA_WIDTH-1:0] rep_base, k;
    logic rep_base_ready;
    
    assign rep_base_ready = (k != (group_count_n / r));

    // rep_base = sum(10 ** (r * k) for k in range(block_size // r))
    always_ff @(posedge clock) begin
        if (reset) begin
            rep_base <= '0;
            k        <= '0;
        end else if (!rep_base_ready) begin
            rep_base <= pow10(k * r) + rep_base;
            k        <= k + 1;
        end
    end
                    
    // lb_r = 10 ** (r - 1) if r != 1 else 1
    // ub_r = ub // rep_base
    logic [`DATA_WIDTH-1:0] lb_r, ub_r, lb_r_reg, ub_r_reg;
    always_comb begin
        lb_r = (r == 1) ? 1 : pow10(r - 1);
        ub_r = ub / rep_base;
    end

    logic bounds_ready;
    always_ff @(posedge clock) begin
        if (reset) begin
            bounds_ready <= '0;
        end else if (rep_base_ready) begin
            bounds_ready <= 1;
            lb_r_reg     <= lb_r;
            ub_r_reg     <= ub_r;
        end
    end

    typedef enum logic [1:0] {CALC_S_CNT, CALC_M_BM, MUL_M_BM, DONE} prim_sub_t;

    prim_sub_t prim_sub_state, next_prim_sub_state;
    logic [`DATA_WIDTH-1:0] CNT, S, CNT_reg, S_reg;
    logic [`LONG_DATA_WIDTH-1:0] BM, M, BM_reg, M_reg,prim_sub, prim_sub_reg;


    // prim_sub += cur_base * rep_base * (lb_r + ub_r) * cnt // 2
    always_comb begin
        next_prim_sub_state = prim_sub_state;
        if (bounds_ready && (ub_r_reg >= lb_r_reg)) begin
            case (prim_sub_state)
                CALC_S_CNT: begin
                // CNT = ub_r - lb_r + 1, S = lb_r + ub_r
                    CNT = ub_r_reg - lb_r_reg + 1;
                    S   = ub_r_reg + lb_r_reg;
                    next_prim_sub_state = CALC_M_BM;
                end
                CALC_M_BM: begin
                    // M = (S * CNT) >> 1, BM = cur_base * rep_base
                    M  = S * CNT;
                    BM = cur_base * rep_base;
                    next_prim_sub_state = MUL_M_BM;
                end
                MUL_M_BM: begin
                    // prim_sub = M * BM
                    prim_sub = M * BM;
                    next_prim_sub_state = DONE;
                end
                default: ;
            endcase
        end else begin
            CNT = '0;
            S   = '0;
            BM  = '0;
            M   = '0;
            prim_sub = prim_sub_reg;
        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin

        end else begin

        end
    end
    
    assign prim_sub_out = prim_sub_reg;

endmodule