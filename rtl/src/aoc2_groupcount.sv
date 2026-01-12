`include "common.svh"

// Counts numbers with repeating digit groups (e.g., for group_count_n=2, counts numbers like 1122, 3344)
// Uses arithmetic series formula: sum from lb to ub = (S * N) / 2, where S = lb + ub, N = count
module group_count #(
    parameter group_count_n = 2
)(
    input logic clock, reset,
    input logic [`DATA_WIDTH-1:0] n_in,     // input value
    input logic [3:0] n_digs_in,            // number of digits in n_in

    output logic group_count_out_valid,
    output logic [`DATA_WIDTH-1:0] group_count_out
);

    localparam group_count_latency = 4;

    logic group_en, cur_base_valid;
    logic [`DATA_WIDTH-1:0] base10;
    logic [`DATA_WIDTH-1:0]      block_size;

    // Only process if digits divide evenly into groups
    assign group_en = (n_digs_in % group_count_n) == '0;

    assign block_size = n_digs_in / group_count_n;
    assign cur_base_valid = (k > group_count_n);

    // resource sharing on LUT
    assign base10 = pow10((k <= group_count_n) ? k * block_size : block_size - 1);

    // Build base (ex. for 4-digit groups: 1 + 10000 + 100000000)
    logic [`DATA_WIDTH-1:0] cur_base;
    int unsigned k, pow_m;
    always_ff @(posedge clock) begin
        if (reset) begin
            cur_base <= '0;
            k     <= '0;
            pow_m <= '0;
        end else if (k <= group_count_n) begin
            k <= k + 1;
            pow_m <= base10;
            cur_base <= pow_m + cur_base;
        end
    end

    // calculate bounds for arith-series
    logic [`DATA_WIDTH-1:0] lb_next, ub_cand_0, ub_cand_1, ub_next, lb, ub;
    always_comb begin
        lb_next = (block_size == 1) ? 1 : base10;
        
        ub_cand_0 = pow10(block_size) - 1;
        ub_cand_1 = n_in / cur_base;

        ub_next = (ub_cand_0 < ub_cand_1) ? ub_cand_0 : ub_cand_1;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            lb <= '0;
            ub <= '0;
        end else begin
            lb <= lb_next;
            ub <= ub_next;
        end
    end

    logic [`DATA_WIDTH-1:0] S_next, N_next, M_next, S, N, M;
    logic [`DATA_WIDTH-1:0] tmp_sum_next, tmp_sum;

    // arith series bounds
    always_comb begin
        S_next = lb + ub;
        N_next = ub - lb + 1;
        M_next = (S * N) >> 1;
        tmp_sum_next = cur_base * M;
    end

    int unsigned tmp_sum_cycles;
    logic tmp_sum_valid;

    always_ff @(posedge clock) begin
        if (reset) begin
            tmp_sum <= '0;
            S       <= '0;
            N       <= '0;
            M       <= '0;
            tmp_sum_cycles <= '0;
        end else if (cur_base_valid) begin
            tmp_sum <= tmp_sum_next;
            S       <= S_next;
            N       <= N_next;
            M       <= M_next;
            
            if (tmp_sum_cycles < group_count_latency)
                tmp_sum_cycles <= tmp_sum_cycles + 1;
        end
    end
    
    assign tmp_sum_valid = (tmp_sum_cycles == group_count_latency);

    logic [`DATA_WIDTH-1:0] prim_sub_out, prim_sub_out_1, prim_sub_out_2;
    logic prim_sub_out_valid, prim_sub_out_1_valid, prim_sub_out_2_valid;
    
    logic [1:0] r, r_next; 

    // calculate duplicates and subtract from current comp
    logic input_valid, input_valid_next;
    prim_calc prim_calc_1 (
        .clock(clock), .reset(reset), .cur_base_valid(cur_base_valid), .input_valid(input_valid),
        .cur_base_in(cur_base), .block_size_in(block_size),
        .ub_in(ub), .r(r),

        .prim_sub_out_valid(prim_sub_out_valid),
        .prim_sub_out(prim_sub_out)
    );

    typedef enum logic [2:1] {
        PRIM_START, PRIM_1_CALC, PRIM_2_CALC, PRIM_END
    } prim_calc_share_t;

    prim_calc_share_t prim_sub_en, prim_sub_en_next; 
    // FSM used to share resource of prim_calc
    always_comb begin
        prim_sub_en_next = prim_sub_en;
        input_valid_next = input_valid;
        r_next = r;
        
        if (cur_base_valid) begin
            case (prim_sub_en)
                PRIM_START: begin
                    prim_sub_en_next = PRIM_1_CALC;
                    input_valid_next = 1;
                    r_next = 2'd1;
                end
                PRIM_1_CALC: begin
                    if (prim_sub_out_valid) begin
                        prim_sub_en_next = PRIM_2_CALC;
                        input_valid_next = '0;
                    end
                end
                PRIM_2_CALC: begin
                    // holds down for cycle
                    if (!input_valid) begin
                        input_valid_next = 1;
                        r_next = 2'd2;
                    end else if (prim_sub_out_valid) begin
                        prim_sub_en_next = PRIM_END;
                    end
                end
                default: ;

            endcase;
        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            input_valid    <= '0;
            prim_sub_en    <= PRIM_START;
            {prim_sub_out_1, prim_sub_out_2} <= '0;
            {prim_sub_out_1_valid, prim_sub_out_2_valid} <= '0;
            r <= 2'd0;
        end else begin
            input_valid <= input_valid_next;
            prim_sub_en <= prim_sub_en_next;
            r <= r_next;

            if (prim_sub_out_valid && input_valid) begin
                if (prim_sub_en == PRIM_1_CALC) begin
                    prim_sub_out_1_valid <= 1;
                    prim_sub_out_1       <= prim_sub_out;
                end else if (prim_sub_en == PRIM_2_CALC) begin
                    prim_sub_out_2_valid <= 1;
                    prim_sub_out_2       <= prim_sub_out;
                end
            end
        end
    end

    // computation for this split
    assign group_count_out = (group_en) ? tmp_sum - prim_sub_out_1 - prim_sub_out_2 : '0;
    assign group_count_out_valid = tmp_sum_valid & prim_sub_out_1_valid & prim_sub_out_2_valid;

endmodule