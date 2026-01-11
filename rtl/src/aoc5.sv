`include "common.svh"
`include "aoc5.svh"

module top (
    input logic clock, reset, 
    input logic data_valid_in, stream_done_in,
    input logic [`BANK_ADDR_WIDTH-1:0] tb_addr_in,
    input tuple_pair_t even_data_in, odd_data_in

);

    tuple_pair_t even_data_out, odd_data_out;
    logic read_en;

    mem mem_inst (
        .clock(clock),
        .write_en(data_valid_in), .read_en(read_en && stream_done_in),
        .row_addr_in((stream_done_in) ? mem_i[`BANK_ADDR_WIDTH-1:0] : tb_addr_in),
        .even_data_in(even_data_in), .odd_data_in(odd_data_in),
    
        .even_data_out(even_data_out), .odd_data_out(odd_data_out)
    );

    logic [`ARR_16_FLAT_WIDTH-1:0] pairs_in_flat, pairs_out_flat;
    logic sort_valid;

    int stream_len, mem_i;

    bitonic_sort_16 sort_16 (
        .clock(clock), .reset(reset), 
        .valid_in(mem_i[3:0] == '0), .stall_in(1'b0),
        .pairs_in_flat(pairs_in_flat),
    
        .valid_out(sort_valid),
        .pairs_out_flat(pairs_out_flat)
    );
    
    always_ff @(posedge clock) begin
        if (reset) begin
            mem_i   <= '0;
            read_en <= 1'b1;
        end else if (stream_done_in && mem_i < stream_len) begin
            mem_i <= mem_i + 2;

            if (mem_i > '0)
                `index_flat(pairs_in_flat, (mem_i - 2) & 4'hF) <= {even_data_out, odd_data_out};
        end
    end

    int insert_i_dbg;
    assign insert_i_dbg = (mem_i - 2) & 4'hF;

    always_ff @(posedge clock) begin
        if (reset) stream_len <= '0;
        else       stream_len <= stream_len + 2;
    end

endmodule