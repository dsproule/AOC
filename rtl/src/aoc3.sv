`include "common.svh"

module top #(
    parameter LINE_LENGTH = 15
)(
    input logic clock, reset, data_in_valid,
    input logic newline,
    input logic [`DATA_WIDTH-1:0] data_in,

    output logic data_out_valid,
    output logic [(`DATA_WIDTH * 2)-1:0] data_out
);

    localparam MAX_CAP = 12;

    logic [`DATA_WIDTH-1:0] i, stack_out;
    logic [$clog2(MAX_CAP):0] peek_i;

    long_stack #(.MAX_CAP(MAX_CAP)) stack (
        .clock(clock), .reset(reset), 
        .data_in_valid(data_in_valid), .data_in(data_in),
        .nums_left(LINE_LENGTH - i), .peek_i(peek_i),
        
        .data_out(stack_out)
    );

    assign data_out_valid = (peek_i == MAX_CAP);

    always_ff @(posedge clock) begin
        if (reset) begin
            i              <= -1;
            peek_i         <= '0;
            data_out       <= '0;
        end else if (data_in_valid) begin
            i <= i + 1;
        end else if (newline && (peek_i < MAX_CAP)) begin
            peek_i   <= peek_i + 1;
            data_out <= data_out * 10 + stack_out;
        end
    end

endmodule