`include "common.svh"
`include "aoc5.svh"

module merger_N #(
    parameter N = 16
) (
    input logic clock, reset, valid_in,
    input logic [ARR_N_FLAT_WIDTH-1:0] pairs_in_flat,

    output logic valid_out, 
    output logic [ARR_N_FLAT_WIDTH-1:0] pairs_out_flat
);
    localparam reach = N >> 1;
    localparam ARR_N_FLAT_WIDTH = N * $bits(tuple_pair_t);
    localparam ARR_N_HALF_FLAT_WIDTH = (N >> 1) * $bits(tuple_pair_t);

    // generalization of pattern at bottom: https://courses.grainger.illinois.edu/cs473/fa2023/lec/notes/04_sortnet.pdf

    generate
        if (N > 1) begin : recursion
            tuple_pair_t pairs_in_unpack [N];
            always_comb begin
                for (int i = 0; i < N; i++) 
                    pairs_in_unpack[i] = `index_flat(pairs_in_flat, i);
            end

            logic [ARR_N_FLAT_WIDTH-1:0] intermed_stage;
            logic intermed_valid;

            logic [1:0] merge_sub_N;
            always_ff @(posedge clock) begin
                if (reset) begin
                    intermed_valid <= 1'b0;
                end else begin
                    intermed_valid <= valid_in;

                    for (int i = 0; i < reach; i++)
                        {`index_flat(intermed_stage, i), `index_flat(intermed_stage, i + reach)} <= cmp_swp(pairs_in_unpack[i], pairs_in_unpack[i + reach], 1'b1);
                end
            end

            merger_N #(.N(reach)) merge_top (
                .clock(clock), .reset(reset), 
                .valid_in(intermed_valid), .pairs_in_flat(intermed_stage[ARR_N_FLAT_WIDTH-1:ARR_N_HALF_FLAT_WIDTH]),

                .valid_out(merge_sub_N[0]), .pairs_out_flat(pairs_out_flat[ARR_N_FLAT_WIDTH-1:ARR_N_HALF_FLAT_WIDTH])
            );
            merger_N #(.N(reach)) merge_low (
                .clock(clock), .reset(reset), 
                .valid_in(intermed_valid), .pairs_in_flat(intermed_stage[ARR_N_HALF_FLAT_WIDTH-1:0]),

                .valid_out(merge_sub_N[1]), .pairs_out_flat(pairs_out_flat[ARR_N_HALF_FLAT_WIDTH-1:0])
            );
            
            assign valid_out = &merge_sub_N;

        end else begin   : base_case
            assign pairs_out_flat = pairs_in_flat;
            assign valid_out      = valid_in;
        end
        
    endgenerate

endmodule

module bitonic_sort_16 (
    input logic clock, reset, 
    input logic valid_in,
    input logic [`ARR_16_FLAT_WIDTH-1:0] pairs_in_flat,
    
    output logic valid_out, saturated_out,
    output logic [`ARR_16_FLAT_WIDTH-1:0] pairs_out_flat
);

    typedef enum logic [1:0] {LOAD_NONE=0, LOAD_TOP=1, LOAD_BOTH=3} bitonic_states_t;

    logic [`ARR_8_FLAT_WIDTH-1:0] top_stage, low_stage, sort_8_out, monotonic_stage;
    logic sort_8_done, top_low_sel;
    bitonic_states_t bitonics_ready, next_bitonics_ready;

    // turn random sequence into bitonic /\
    sorter_8 sort_8 (
        .clock(clock), .reset(reset), 
        .valid_in(valid_in), .asc_in(top_low_sel),
        .pairs_in_flat((top_low_sel) ? pairs_in_flat[`ARR_16_FLAT_WIDTH-1:`ARR_8_FLAT_WIDTH] : 
                                                    pairs_in_flat[`ARR_8_FLAT_WIDTH-1:0]),
    
        .valid_out(sort_8_done),
        .pairs_out_flat(monotonic_stage)
    );

    always_comb begin
        next_bitonics_ready = bitonics_ready;

        if (sort_8_done) begin
            case (bitonics_ready)
                LOAD_NONE: next_bitonics_ready = LOAD_TOP;
                LOAD_TOP:  next_bitonics_ready = LOAD_BOTH;
                LOAD_BOTH: next_bitonics_ready = LOAD_TOP;
            endcase
        end else if (bitonics_ready == LOAD_BOTH) next_bitonics_ready = LOAD_NONE;
    end

    // recursive call of bitonic network
    merger_N #(.N(16)) merge (
        .clock(clock), .reset(reset),
        .valid_in(&bitonics_ready), .pairs_in_flat({top_stage, low_stage}),

        .valid_out(valid_out), .pairs_out_flat(pairs_out_flat)
    );
    
    always_ff @(posedge clock) begin
        if (reset) begin 
            bitonics_ready <= 2'b0;
            top_low_sel <= 1'b0;
        end else begin 
            bitonics_ready <= next_bitonics_ready;

            if      (next_bitonics_ready == LOAD_TOP) top_stage <= monotonic_stage;
            else if (next_bitonics_ready == LOAD_BOTH) low_stage <= monotonic_stage;

            if (valid_in) top_low_sel <= ~top_low_sel;
        end
    end 

endmodule