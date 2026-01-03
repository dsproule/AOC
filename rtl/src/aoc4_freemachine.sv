module freemachine #(
    parameter start_row = 0,
    parameter end_row   = `BANK_DEPTH
)(
    input logic clock, reset,
    input logic [`TX_DATA_WIDTH] partial_vec_in,
    input logic sweep_start, ack_in,

    output logic changed_out, done_out, write_en_out, read_en_out,
    output logic [`BANK_ADDR_WIDTH-1:0] row_addr_out,
    output logic [`COL_ADDR_WIDTH-1:0]  col_addr_out,
    output logic [`TX_DATA_WIDTH]       partial_vec_out
);

    logic regs_valid;
    logic [`GRID_VEC_ALIGN_N-1:0] regs [3];

    logic [`BANK_ADDR_WIDTH-1:0] mid_row_i;

    
endmodule