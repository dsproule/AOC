`include "common.svh"

module top #(
    parameter line_length = 15
)(
    input logic clock, reset, data_in_valid,
    input logic newline,
    input logic [`DATA_WIDTH-1:0] data_in,

    output logic data_out_valid,
    output logic [`DATA_WIDTH-1:0] data_out
);

    logic [`DATA_WIDTH-1:0] i;

    long_stack stack(
        .clock(clock), .reset(reset), 
        .data_in_valid(data_in_valid), .data_in(data_in),
        .nums_left(line_length - i),
        
        .full()
    );

    always_ff @(posedge clock) begin
        if (reset) begin
            i <= -1;
        end else if (data_in_valid) begin
            i <= i + 1;
        end
    end

endmodule