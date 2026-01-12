`include "common.svh"

module splitter #(
    parameter LINE_LENGTH = 141
)(
    input logic clock, reset, en,
    input logic split_in,

    output logic [`DATA_WIDTH-1:0] count_out
);
    logic [`DATA_WIDTH-1:0] data [LINE_LENGTH];

    assign count_out   = data[0];
    assign valid_split = |count_out && split_in;

    int rot_i;
    int i;
    // circular shift reg moves value around and updates in-place if collision
    always_ff @(posedge clock) begin
        if (reset) begin
            for (rot_i = 0; rot_i < LINE_LENGTH; rot_i++)
                data[rot_i] <= '0;
            data[LINE_LENGTH / 2] <= 1;
            i <= '0;
        end else if (en) begin
            for (rot_i = 1; rot_i < LINE_LENGTH - 2; rot_i++)
                data[rot_i] <= data[rot_i + 1];
            data[LINE_LENGTH - 2] <= (valid_split) ? data[LINE_LENGTH - 1] + data[0] : data[LINE_LENGTH - 1];
            data[LINE_LENGTH - 1] <= (valid_split) ? '0 : data[0];
            data[0]               <= (valid_split) ? data[1] + data[0] : data[1];

            i <= (i == LINE_LENGTH - 1) ? '0 : i + 1;
        end
    end

endmodule