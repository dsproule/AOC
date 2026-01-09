`include "common.svh"
`include "aoc5.svh"

module top (
    input logic clock, reset, 
    input logic data_valid_in, stream_done_in,
    input logic [`BANK_ADDR_WIDTH-1:0] tb_addr_in,
    input tuple_pair_t even_data_in, odd_data_in

);
    typedef enum logic [1:0] {DATA_INIT, SORT_STREAMS} phase_t;

    mem mem_inst (
        .clock(clock),
        .write_en(data_valid_in), .read_en(1'b0),
        .row_addr_in(tb_addr_in),
        .even_data_in(even_data_in), .odd_data_in(odd_data_in),
    
        .even_data_out(), .odd_data_out()
    );

    logic [`ARR_16_FLAT_WIDTH-1:0] pairs_in_flat, pairs_out_flat;
    logic sort_valid;

    bitonic_sort_16 sort_16 (
        .clock(clock), .reset(reset), 
        .valid_in(valid_in), .stall_in(1'b0),
        .pairs_in_flat(pairs_in_flat),
    
        .valid_out(sort_valid),
        .pairs_out_flat(pairs_out_flat)
    );
    
    logic [3:0] insert_i;
    always_ff @(posedge clock) begin
        if (reset) begin
            insert_i <= '0;
        end else begin
            insert_i <= (insert_i == 14) ? '0 : insert_i + 2;
        end
    end

    phase_t phase;
    always_ff @(posedge clock) begin
        if (reset)               phase <= DATA_INIT;
        else if (stream_done_in) phase <= SORT_STREAMS; 
    end

endmodule