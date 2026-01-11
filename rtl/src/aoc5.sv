`include "common.svh"
`include "aoc5.svh"

module top (
    input logic clock, reset, 
    input logic data_valid_in, stream_done_in,
    input logic [`BANK_ADDR_WIDTH-1:0] tb_addr_in,
    input tuple_pair_t even_data_in, odd_data_in

);

    typedef enum logic {PING=0, PONG} ping_pong_t;

    tuple_pair_t even_data_out [2], odd_data_out [2];
    logic read_en;

    mem mem_ping (
        .clock(clock),
        .write_en(data_valid_in), .read_en(stream_done_in),
        .row_addr_in((stream_done_in) ? mem_i[`BANK_ADDR_WIDTH-1:0] : tb_addr_in),
        .even_data_in(even_data_in), .odd_data_in(odd_data_in),
    
        .even_data_out(even_data_out[0]), .odd_data_out(odd_data_out[0])
    );
    
    // mem mem_pong (
    //     .clock(clock),
    //     .write_en(), .read_en(),
    //     .row_addr_in(),
    //     .even_data_in(), .odd_data_in(),
    
    //     .even_data_out(), .odd_data_out()
    // );

    logic [`ARR_16_FLAT_WIDTH-1:0] pairs_in_flat, pairs_out_flat;
    logic sort_out_valid, sort_acc;

    int stream_len, mem_i;
    logic sort_stage_valid;

    bitonic_sort_16 sort_16 (
        .clock(clock), .reset(reset), 
        .valid_in(sort_stage_valid), 
        .pairs_in_flat(pairs_in_flat),
    
        .valid_out(sort_out_valid),
        .pairs_out_flat(pairs_out_flat)
    );
    
    logic [3:0] insert_i;
    assign insert_i = (mem_i - 2) & 4'hF;

    logic parity_clock, sort_stage_parity;
    always_ff @(posedge clock) begin
        if (reset) parity_clock <= '0;
        else parity_clock <= ~parity_clock;
    end

    // handles the cycling for loading regs for sort
    always_ff @(posedge clock) begin
        if (reset) begin
            mem_i            <= '0;
            sort_stage_valid <= 1'b0;
        end else if (stream_done_in && mem_i < stream_len && !sort_stage_valid) begin
            mem_i <= mem_i + 2;

            `index_flat(pairs_in_flat, insert_i)     <= even_data_out[PING];
            `index_flat(pairs_in_flat, insert_i + 1) <= odd_data_out[PING];

            // if mod_6 -> latch parity
            if ((mem_i & 4'hF) == '0 && mem_i != '0) begin
                sort_stage_valid  <= 1'b1;
                sort_stage_parity <= parity_clock;
            end

        end else if (parity_clock == sort_stage_parity) sort_stage_valid <= 1'b0;
    end

    // handle the initial merging of 32 values
    logic [1:0] merge_regs_valid;
    int merge_0_regs_cnt, merge_1_regs_cnt;
    logic [`ARR_16_FLAT_WIDTH-1:0] merge_regs_flat [2];

    assign sort_acc = (merge_regs_valid < 2) && stream_done_in;

    always_ff @(posedge clock) begin
        if (reset) begin
            merge_regs_valid <= '0;
        end else if (sort_out_valid && (merge_regs_valid != 2'b11)) begin
            merge_regs_flat[merge_regs_valid] <= pairs_out_flat;
            merge_regs_valid <= {merge_regs_valid[0], 1'b1};
            merge_0_regs_cnt <= 16;
            merge_1_regs_cnt <= 16;
        end if (merge_regs_valid == 2'b11) begin
            
        end
    end 

    tuple_pair_t comb_0_swp [4], comb_1_swp [4], comb_2_swp [4];

    always_comb begin
        {comb_0_swp[0], comb_0_swp[1]} = cmp_swp(`index_flat(merge_regs_flat[0], 0), `index_flat(merge_regs_flat[0], 1), 1'b1);
        {comb_0_swp[2], comb_0_swp[3]} = cmp_swp(`index_flat(merge_regs_flat[1], 0), `index_flat(merge_regs_flat[1], 1), 1'b1);
        
        {comb_1_swp[0], comb_1_swp[1]} = cmp_swp(comb_0_swp, comb_0_swp, 1'b1);
        {comb_1_swp[2], comb_1_swp[3]} = cmp_swp(comb_0_swp, comb_0_swp, 1'b1);

    end


    // simple counter to get the overall stream length. 
    always_ff @(posedge clock) begin
        if      (reset)            stream_len <= '0;
        else if (!stream_done_in)  stream_len <= stream_len + 2;
    end

endmodule