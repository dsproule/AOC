`include "common.svh"

module long_stack #(
    parameter MAX_CAP = 8
)(
    input logic clock, reset, data_in_valid,
    input logic [`DATA_WIDTH-1:0] data_in, 

    output logic full, empty
);

    logic [`DATA_WIDTH-1:0] data [MAX_CAP-1:0];

    genvar dbg_i;
    generate for (dbg_i = 0; dbg_i < MAX_CAP; dbg_i++) begin : dbg
        logic [`DATA_WIDTH-1:0] dbg_data;
        assign dbg_data = data[dbg_i];
    end endgenerate

    logic [$clog2(MAX_CAP):0] sp, next_sp;

    assign full  = (sp == MAX_CAP);
    assign empty = (sp == '0);

    always_comb begin
        if (empty) begin
            next_sp = (data_in_valid) ? sp + 1 : sp;
        end else begin
            next_sp = (data_in_valid && !full) ? sp + 1 : sp;
        end        
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            sp <= '0;
        end else begin
            if (data_in_valid && !full)
                data[sp] <= data_in;
            sp <= next_sp;
        end
    end

endmodule