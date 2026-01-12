`include "common.svh"

module long_stack #(
    parameter MAX_CAP = 12
)(
    input logic clock, reset, data_in_valid,
    input logic [`DATA_WIDTH-1:0] data_in, nums_left,
    input logic [$clog2(MAX_CAP):0] peek_i,

    output logic [`DATA_WIDTH-1:0] data_out
);

    logic [`DATA_WIDTH-1:0] data [MAX_CAP];

    // Signal updates
    logic [$clog2(MAX_CAP):0] sp, next_sp;

    logic full;
    assign full     = (sp == MAX_CAP);
    assign data_out = data[peek_i];

    assign next_sp = (data_in_valid && !full) ? sp + 1 : sp;
    
    // long-pop logic. builds a map that we can perform bitwise ops on
    logic [MAX_CAP-1:0] less_than, less_than_suf, forward_cand;
    logic [$clog2(MAX_CAP):0] insert_i, forward_i;

    always_comb begin
        forward_i = sp - 1;
        for (int i = MAX_CAP - 1; i >= 0; i--) begin
            less_than[i] = (data[i] < data_in) && (i <= sp);
            forward_cand[i] = (nums_left >= MAX_CAP - i + 1);

            // after the first iter build the prefs
            less_than_suf[i] = (i == sp - 1 || i == MAX_CAP - 1) ? 
                                forward_cand[i] & less_than[i] : forward_cand[i] & less_than[i] & less_than_suf[i + 1];

            if (less_than_suf[i])
                forward_i = i;
        end

        insert_i = (|less_than_suf) ? forward_i + 1 : next_sp;
    end

    logic insert_valid;
    assign insert_valid = (|less_than_suf || !full);

    always_ff @(posedge clock) begin
        if (reset) begin
            sp <= '0;
            for (int reset_i = 0; reset_i < MAX_CAP; reset_i++)
                data[reset_i] <= -1;
        end else begin
            if (data_in_valid && insert_valid)
                data[insert_i - 1] <= data_in;
            sp <= insert_i;
        end
    end

endmodule