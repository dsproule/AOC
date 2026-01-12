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
        .write_en(data_valid_in), .read_en(mem_load_valid),
        .row_addr_in((stream_done_in) ? mem_load_i[`BANK_ADDR_WIDTH-1:0] : tb_addr_in),
        .even_data_in(even_data_in), .odd_data_in(odd_data_in),
    
        .even_data_out(even_data_out[0]), .odd_data_out(odd_data_out[0])
    );
    
    logic [`ARR_16_FLAT_WIDTH-1:0] sort_16_pairs_in_flat, sort_16_pairs_out_flat;
    logic sort_16_out_valid, sort_acc;

    int stream_len, mem_load_i;
    logic sort_16_in_valid;

    bitonic_sort_16 sort_16 (
        .clock(clock), .reset(reset), 
        .valid_in(sort_16_in_valid), 
        .pairs_in_flat(sort_16_pairs_in_flat),
    
        .valid_out(sort_16_out_valid),
        .pairs_out_flat(sort_16_pairs_out_flat)
    );
    
    logic [3:0] insert_i;
    assign insert_i = (mem_load_i - 2) & 4'hF;

    logic parity_clock, sort_stage_parity;
    always_ff @(posedge clock) begin
        if (reset) parity_clock <= '0;
        else parity_clock <= ~parity_clock;
    end

    logic final_sort_valid;
    logic mem_load_valid;
    assign mem_load_valid = (stream_done_in && mem_load_i <= stream_len && !sort_16_in_valid);

    // handles the cycling for loading regs for sort
    always_ff @(posedge clock) begin
        if (reset) begin
            mem_load_i        <= '0;
            sort_16_in_valid <= 1'b0;
            final_sort_valid <= 1'b0;
        end else if (stream_done_in) begin
            if (mem_load_valid) begin
                mem_load_i <= mem_load_i + 2;

                `index_flat(sort_16_pairs_in_flat, insert_i)     <= even_data_out[PING];
                `index_flat(sort_16_pairs_in_flat, insert_i + 1) <= odd_data_out[PING];

                // if mod_6 -> latch parity
                if ((mem_load_i & 4'hF) == '0 && mem_load_i != '0) begin
                    sort_16_in_valid  <= 1'b1;
                    sort_stage_parity <= parity_clock;
                end
            end else if (mem_load_i >= stream_len && !final_sort_valid) begin
                mem_load_i <= mem_load_i + 1;
                if ((mem_load_i & 4'hF) == '0) begin
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
    logic merge_write_valid;
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

    assign merge_write_valid = (merge_regs_cnt < 16);

    mem mem_pong (
        .clock(clock),
        .write_en(merge_write_valid), .read_en(1'b0),
        .row_addr_in(`BANK_ADDR_WIDTH'(mem_write_i + merge_regs_cnt)),
        .even_data_in(`index_flat(merge_regs_flat, 0)), .odd_data_in(`index_flat(merge_regs_flat, 1)),
    
        .even_data_out(), .odd_data_out()
    );

    // simple counter to get the overall stream length. 
    always_ff @(posedge clock) begin
        if      (reset)            stream_len <= '0;
        else if (!stream_done_in)  stream_len <= stream_len + 2;
    end

endmodule