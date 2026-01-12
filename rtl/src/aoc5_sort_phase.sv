`include "common.svh"
`include "aoc5.svh"

module sort_phase (
    input logic clock, reset, 
    input logic en_in,
    input int stream_len_in,

    // ping memory
    input  tuple_pair_t even_data_in, odd_data_in,
    output logic [`BANK_ADDR_WIDTH-1:0] ping_addr_out,
    output logic ping_read_en,

    // pong memory
    output logic [`BANK_ADDR_WIDTH-1:0] pong_addr_out,
    output tuple_pair_t even_data_out, odd_data_out,
    output logic pong_write_en,

    output logic phase_done_out

);
    logic [`ARR_16_FLAT_WIDTH-1:0] sort_16_pairs_in_flat, sort_16_pairs_out_flat;
    logic sort_16_out_valid, sort_acc;

    logic sort_16_in_valid;

    bitonic_sort_16 sort_16 (
        .clock(clock), .reset(reset), 
        .valid_in(sort_16_in_valid), 
        .pairs_in_flat(sort_16_pairs_in_flat),
    
        .valid_out(sort_16_out_valid),
        .pairs_out_flat(sort_16_pairs_out_flat)
    );
    
    logic [3:0] insert_i;
    assign insert_i = (ping_addr_out - 2) & 4'hF;

    logic parity_clock, sort_stage_parity;
    always_ff @(posedge clock) begin
        if (reset) parity_clock <= '0;
        else parity_clock <= ~parity_clock;
    end

    logic final_sort_valid;
    assign ping_read_en = (en_in && ping_addr_out <= stream_len_in && !sort_16_in_valid);

    logic init_delay;
    // handles the cycling for loading regs for sort
    always_ff @(posedge clock) begin
        if (reset) begin
            ping_addr_out        <= '0;
            sort_16_in_valid <= 1'b0;
            final_sort_valid <= 1'b0;
            init_delay       <= 1'b1;
        end else if (en_in) begin
            init_delay <= 1'b0;

            if (ping_read_en) begin
                if (!init_delay) ping_addr_out <= ping_addr_out + 2;

                `index_flat(sort_16_pairs_in_flat, insert_i)     <= even_data_in;
                `index_flat(sort_16_pairs_in_flat, insert_i + 1) <= odd_data_in;

                // if mod_6 -> latch parity
                if ((ping_addr_out & 4'hF) == '0 && ping_addr_out != '0) begin
                    sort_16_in_valid  <= 1'b1;
                    sort_stage_parity <= parity_clock;
                end
            end else if (ping_addr_out >= stream_len_in && !final_sort_valid) begin
                ping_addr_out <= ping_addr_out + 1;
                if ((ping_addr_out & 4'hF) == '0) begin
                    sort_16_in_valid  <= 1'b1;
                    sort_stage_parity <= parity_clock;
                    final_sort_valid <= 1'b1;
                end
            end else if (parity_clock == sort_stage_parity) begin
                sort_16_pairs_in_flat <=  '0 - 1;
                sort_16_in_valid <= 1'b0;
            end
        end
    end

    // handle the initial merging of 32 values
    logic [`ARR_16_FLAT_WIDTH-1:0] merge_regs_flat;
    int merge_regs_cnt, mem_write_i;
    always_ff @(posedge clock) begin
        if (reset) begin
            merge_regs_cnt  <= 18;
            mem_write_i     <= '0;
        end else begin
            merge_regs_flat <= (merge_regs_flat >> (2 * $bits(tuple_pair_t)));
            if (sort_16_out_valid) begin
                merge_regs_flat <= sort_16_pairs_out_flat;
                merge_regs_cnt  <= '0;
            end

            if (merge_regs_cnt <= 16) merge_regs_cnt <= merge_regs_cnt + 2;
            if (merge_regs_cnt == 16) mem_write_i    <= mem_write_i    + 16;
        end
    end

    assign pong_write_en = (merge_regs_cnt < 16) && en_in;
    
    assign phase_done_out = (mem_write_i > stream_len_in);
    
    // writeback control
    assign pong_addr_out = mem_write_i + merge_regs_cnt;
    assign even_data_out = `index_flat(merge_regs_flat, 0);
    assign odd_data_out  = `index_flat(merge_regs_flat, 1);

    // simple counter to get the overall stream length. 
    // always_ff @(posedge clock) begin
    //     if      (reset)            stream_len <= '0;
    //     else if (!en_in)  stream_len <= stream_len + 2;
    // end

endmodule