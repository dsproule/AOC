`ifndef AOC5__
`define AOC5__

typedef struct packed {
    logic [`DATA_WIDTH-1:0] first;
    logic [`DATA_WIDTH-1:0] second;
} tuple_pair_t;

typedef struct packed {
    tuple_pair_t first;
    tuple_pair_t second;
} swp_tuple_pair_t;

typedef enum logic {PING=0, PONG} ping_pong_t;

function automatic swp_tuple_pair_t cmp_swp (
    input tuple_pair_t a, b,
    input logic asc
);
    logic swp;
    swp_tuple_pair_t result;

    swp = (a.first > b.first) == asc;

    if (swp) begin
        result.first  = b;
        result.second = a;
    end else begin
        result.first  = a;
        result.second = b;
    end

    cmp_swp = result;
endfunction

`define pass_through(prev_stage, next_stage, N) begin for (int i = 0; i < N; i++) next_stage[i] <= prev_stage[i]; end

`define index_flat(array, i) array[(i + 1) * $bits(tuple_pair_t) - 1 -: $bits(tuple_pair_t)]

`define ARR_8_FLAT_WIDTH (8 * $bits(tuple_pair_t))
`define ARR_16_FLAT_WIDTH (16 * $bits(tuple_pair_t))

`define BANK_DEPTH 256
`define BANK_ADDR_WIDTH $clog2(`BANK_DEPTH)

// iverilog simulator disallows defining these in modules
typedef enum logic [1:0] {DATA_INIT, DATA_SORT, DATA_MERGE, DATA_INTVS} phase_t;

`endif