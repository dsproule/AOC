`include "common.svh"
`include "aoc5.svh"

module top (
    input logic clock, reset, 
    input logic data_valid_in, stream_done_in,
    input logic [`BANK_ADDR_WIDTH-1:0] tb_addr_in,
    input tuple_pair_t tb_even_data_in, tb_odd_data_in
);
    `define current_state(PHASE) (phase_state == PHASE)

    logic pingpong;

    logic [`BANK_ADDR_WIDTH-1:0] sort_ping_addr;
    logic read_en_pingpong [2], write_en_pingpong [2];
    phase_t phase_state;

    logic [`BANK_ADDR_WIDTH-1:0] row_addr_pingpong [2];
    tuple_pair_t even_data_in_pingpong [2], odd_data_in_pingpong [2];
    tuple_pair_t even_data_out_pingpong [2], odd_data_out_pingpong [2];

    logic [`BANK_ADDR_WIDTH-1:0] merge_read_addr, merge_write_addr;

    assign ping_read_en = sort_read_en;

    always_comb begin
        // Different phases need to claim ownership of signals
        {row_addr_pingpong[PING], row_addr_pingpong[PONG]}         = '0;
        {even_data_in_pingpong[PING], even_data_in_pingpong[PONG]} = '0;
        {odd_data_in_pingpong[PING], odd_data_in_pingpong[PING]}   = '0;
        {write_en_pingpong[PONG], write_en_pingpong[PING]}         = '0;
        {read_en_pingpong[PONG], read_en_pingpong[PING]}           = '0;
        
        case (phase_state)
            DATA_INIT: begin
                // addressing
                row_addr_pingpong[PING] = tb_addr_in;

                // dataflow
                even_data_in_pingpong[PING] = tb_even_data_in;
                odd_data_in_pingpong[PING] = tb_odd_data_in;

                write_en_pingpong[PING] = data_valid_in;
            end
            
            DATA_SORT: begin
                // addressing
                row_addr_pingpong[PING] = sort_ping_addr;
                row_addr_pingpong[PONG] = sort_pong_addr;

                // dataflow
                even_data_in_pingpong[PONG] = sort_even_data_pong;
                odd_data_in_pingpong[PONG] = sort_odd_data_pong;

                write_en_pingpong[PONG] = sort_write_en;
                read_en_pingpong[PING] = sort_read_en;
            end
            
            DATA_MERGE: begin
                // looks much scarier than it is. Just need to swap all connections for read/write
                // based on whether we want ping or pong.
                if (pingpong) begin
                    row_addr_pingpong[PING] = merge_read_addr;
                     read_en_pingpong[PING] = merge_read_en;
                     merge_odd_in_data      = odd_data_out_pingpong[PING];
                    merge_even_in_data      = even_data_out_pingpong[PING];
                    
                    row_addr_pingpong[PONG] = merge_write_addr;
                    write_en_pingpong[PONG] = merge_write_en;
                    even_data_in_pingpong[PONG] = merge_even_out_data;
                    odd_data_in_pingpong[PONG] = merge_odd_out_data;
                end else begin
                    row_addr_pingpong[PONG] = merge_read_addr;
                     read_en_pingpong[PONG] = merge_read_en;
                     merge_odd_in_data      = odd_data_out_pingpong[PONG];
                    merge_even_in_data      = even_data_out_pingpong[PONG];

                    row_addr_pingpong[PING] = merge_write_addr;
                    write_en_pingpong[PING] = merge_write_en;
                    even_data_in_pingpong[PING] = merge_even_out_data;
                    odd_data_in_pingpong[PING] = merge_odd_out_data;
                end
            end
        endcase
    end

    mem mem_ping (
        .clock(clock),
        .write_en(write_en_pingpong[PING]), .read_en(read_en_pingpong[PING]),
        .row_addr_in(row_addr_pingpong[PING]),
        .even_data_in(even_data_in_pingpong[PING]), .odd_data_in(odd_data_in_pingpong[PING]),
    
        .even_data_out(even_data_out_pingpong[PING]), .odd_data_out(odd_data_out_pingpong[PING])
    );

    mem mem_pong (
        .clock(clock),
        .write_en(write_en_pingpong[PONG]), .read_en(read_en_pingpong[PONG]),
        .row_addr_in(row_addr_pingpong[PONG]),
        .even_data_in(even_data_in_pingpong[PONG]), .odd_data_in(odd_data_in_pingpong[PONG]),

        .even_data_out(even_data_out_pingpong[PONG]), .odd_data_out(odd_data_out_pingpong[PONG])
    );

    logic sort_done, sort_read_en, sort_write_en;
    logic sort_en, phase_merge_en;

    assign sort_en = (`current_state(DATA_SORT)) || stream_done_in;
    assign phase_merge_en = (`current_state(DATA_MERGE));

    logic [`BANK_ADDR_WIDTH-1:0] sort_pong_addr;
    tuple_pair_t sort_even_data_pong, sort_odd_data_pong;

    int stream_len;

    sort_phase sort_phase_inst (
        .clock(clock), .reset(reset), 
        .en_in(sort_en), .stream_len_in(stream_len),
        
        // ping data 
        .even_data_in(even_data_out_pingpong[PING]), .odd_data_in(odd_data_out_pingpong[PING]),
        .ping_read_en(sort_read_en), .ping_addr_out(sort_ping_addr),
        
        // pong data
        .pong_addr_out(sort_pong_addr),
        .even_data_out(sort_even_data_pong), .odd_data_out(sort_odd_data_pong),
        .pong_write_en(sort_write_en),
        .phase_done_out(sort_done)
    );

    logic merge_read_en, merge_write_en;
    tuple_pair_t merge_even_in_data, merge_odd_in_data;
    tuple_pair_t merge_even_out_data, merge_odd_out_data;

    merge_phase merge_phase_inst (
        .clock(clock), .reset(reset), 
        .en_in(phase_merge_en), .stream_len_in(stream_len),

        // read path
        .even_data_in(merge_even_in_data), .odd_data_in(merge_odd_in_data),
        .read_addr_out(merge_read_addr),
        .read_en_out(merge_read_en),

        // write path
        .even_data_out(merge_even_out_data), .odd_data_out(merge_odd_out_data),
        .write_addr_out(merge_write_addr),
        .write_en_out(merge_write_en),

        .phase_done_out(), .pingpong(pingpong)
    );

    always_ff @(posedge clock) begin
        if (reset) begin
            phase_state <= DATA_INIT;
        end else begin
            case (phase_state)
                DATA_INIT: if (stream_done_in)  phase_state <= DATA_SORT;
                DATA_SORT: if (sort_done) phase_state <= DATA_MERGE;
            endcase
        end
    end

    // simple counter to get the overall stream length. 
    always_ff @(posedge clock) begin
        if      (reset) stream_len <= '0;
        else if (phase_state == DATA_INIT && !stream_done_in)  stream_len <= stream_len + 2;
    end

endmodule