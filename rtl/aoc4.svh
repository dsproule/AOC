`ifndef AOC4__
`define AOC4__

`define MAX_ROWS 139
`define MAX_COLS `MAX_ROWS

`define MACH_N 6
`define BANK_DEPTH `MAX_ROWS
`define MACH_ROWS `BANK_DEPTH / `MACH_N
`define BANK_ADDR_WIDTH $clog2(`BANK_DEPTH)

`define GRID_VEC_ALIGN_N (((`MAX_COLS + 2 + `TX_DATA_WIDTH - 1) / `TX_DATA_WIDTH) * `TX_DATA_WIDTH)
`define COL_ADDR_WIDTH $clog2(`GRID_VEC_ALIGN_N)
`define TX_DATA_WIDTH 32

`define VEC_OFFSET(col_i) ((col_i & ~(`TX_DATA_WIDTH - 1)))

// more complex functionality required by this tb
typedef struct packed {
    logic [`BANK_ADDR_WIDTH-1:0] row_addr;
    logic [`TX_DATA_WIDTH-1:0]   partial_vec;
    logic [`COL_ADDR_WIDTH-1:0]  col_addr;

    logic write_en;
    logic read_en;
    logic staging;
} tb_packet_t;

`endif