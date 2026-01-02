`ifndef AOC4__
`define AOC4__

`define MAX_ROWS 139
`define MAX_COLS `MAX_ROWS

`define MACH_N 2
`define BANK_DEPTH ((`MAX_ROWS + `MACH_N - 1) / `MACH_N)
`define BANK_ADDR_WIDTH $clog2(`BANK_DEPTH)

`define GRID_VEC_ALIGN_N (((`MAX_COLS + 2 + `TX_DATA_WIDTH - 1) / `TX_DATA_WIDTH) * `TX_DATA_WIDTH)
`define COL_ADDR_WIDTH $clog2(`GRID_VEC_ALIGN_N)
`define TX_DATA_WIDTH 32

`endif