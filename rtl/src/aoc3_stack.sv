`include "common.svh"

module long_stack #(
    parameter MAX_CAP = 12
)(
    input logic clock, reset, data_in_valid,
    input logic [`DATA_WIDTH-1:0] data_in, nums_left,

    output logic full
);

    logic [`DATA_WIDTH-1:0] data [MAX_CAP-1:0];

    // Remove after debug ---------------
    genvar dbg_i;
    generate for (dbg_i = 0; dbg_i < MAX_CAP; dbg_i++) begin : dbg
        logic [`DATA_WIDTH-1:0] dbg_data;
        assign dbg_data = data[dbg_i];
    end endgenerate

    // Signal updates ---------------    
    logic [$clog2(MAX_CAP):0] sp, next_sp;

    assign full = (sp == MAX_CAP);

    assign next_sp = (data_in_valid && !full) ? sp + 1 : sp;
    
    // long-pop logic ---------------
    logic [MAX_CAP-1:0] less_than, less_than_suf;
    logic [$clog2(MAX_CAP):0] insert_i, forward_i;

    always_comb begin
        forward_i = sp - 1;
        for (int i = MAX_CAP - 1; i >= 0; i--) begin
            less_than[i] = (data[i] < data_in) && (i <= sp) && (nums_left >= MAX_CAP - i + 1);

            // after the first iter build the prefs
            less_than_suf[i] = (i == MAX_CAP - 1) ? 
                                less_than[i] : less_than[i] & less_than_suf[i + 1];

            if (less_than_suf[i])
                forward_i = i;
        end

        insert_i = (|less_than_suf) ? forward_i + 1: next_sp;
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