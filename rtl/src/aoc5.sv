`include "common.svh"
`include "aoc5.svh"

module top (
    input logic clock, reset, 
    input logic data_valid_in, stream_done_in,
    input logic [`BANK_ADDR_WIDTH-1:0] tb_addr_in,
    input tuple_pair_t even_data_in, odd_data_in
);

    int sort_phase_ping_addr;
    logic read_en_pingpong [2], write_en_pingpong [2];

    logic [`BANK_ADDR_WIDTH-1:0] row_addr_pingpong [2];
    tuple_pair_t even_data_out_pingpong [2], odd_data_out_pingpong [2];
    tuple_pair_t even_data_in_pingpong [2], odd_data_in_pingpong [2];

    assign row_addr_pingpong[PING] = (stream_done_in) ? sort_phase_ping_addr[`BANK_ADDR_WIDTH-1:0] : tb_addr_in;

    mem mem_ping (
        .clock(clock),
        .write_en(data_valid_in), .read_en(ping_read_en),
        .row_addr_in(row_addr_pingpong[PING]),
        .even_data_in(even_data_in), .odd_data_in(odd_data_in),
    
        .even_data_out(even_data_out_pingpong[PING]), .odd_data_out(odd_data_out_pingpong[PING])
    );

    mem mem_pong (
        .clock(clock),
        .write_en(write_en_pingpong[PONG]), .read_en(1'b0),
        .row_addr_in(row_addr_pingpong[PONG]),
        .even_data_in(even_data_in_pingpong[PONG]), .odd_data_in(odd_data_in_pingpong[PONG])
    );

    sort_phase sort_phase_inst (
        .clock(clock), .reset(reset), 
        .en_in(stream_done_in),
        
        // ping data 
        .even_data_in(even_data_out_pingpong[PING]), .odd_data_in(odd_data_out_pingpong[PING]),
        .ping_read_en(ping_read_en), .ping_addr_out(sort_phase_ping_addr),
        
        // pong data
        .pong_addr_out(row_addr_pingpong[PONG]),
        .even_data_out(even_data_in_pingpong[PONG]), .odd_data_out(odd_data_in_pingpong[PONG]),
        .pong_write_en(write_en_pingpong[PONG])
    );

endmodule