`include "common.svh"
`include "aoc5.svh"

module mem(
    input logic clock,
    input logic write_en, read_en,
    input logic [`BANK_ADDR_WIDTH-1:0] row_addr_in,
    input tuple_pair_t even_data_in, odd_data_in,
    
    output tuple_pair_t even_data_out, odd_data_out
);

    single_port_sync_ram #(
        .ADDR_WIDTH(`BANK_ADDR_WIDTH), .DEPTH(`BANK_DEPTH), .DATA_WIDTH($bits(tuple_pair_t))
    ) bank_even (
        .clock(clock),
        .addr({row_addr_in[`BANK_ADDR_WIDTH-1:1], 1'b0}),
        .write_data(even_data_in),
        .bank_en(write_en || read_en), .write_en(write_en),

        .read_data(even_data_out)
    );
    
    single_port_sync_ram #(
        .ADDR_WIDTH(`BANK_ADDR_WIDTH), .DEPTH(`BANK_DEPTH), .DATA_WIDTH($bits(tuple_pair_t))
    ) bank_odd (
        .clock(clock),
        .addr({row_addr_in[`BANK_ADDR_WIDTH-1:1], 1'b0}),
        .write_data(odd_data_in),
        .bank_en(write_en || read_en), .write_en(write_en),

        .read_data(odd_data_out)
    );

endmodule