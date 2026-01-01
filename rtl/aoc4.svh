`ifndef AOC4__
`define AOC4__

`define MAX_ROWS 139
`define MAX_COLS `MAX_ROWS
`define MEM_ADDR_WIDTH $clog2(`MAX_ROWS)

// used to denote a single row in the grid
`define GRID_VEC_ALIGN_N (((`MAX_COLS + 2 + `TX_DATA_WIDTH - 1) / `TX_DATA_WIDTH) * `TX_DATA_WIDTH)

`define TX_DATA_WIDTH 8

`endif