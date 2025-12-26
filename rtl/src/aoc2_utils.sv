`include "common.svh"

module get_digs(
    input logic [`DATA_WIDTH-1:0] data_in,

    output logic [`DATA_WIDTH-1:0] digs_out
);

    always_comb begin
        digs_out = 1;
        for (int i = 10; i > 0; i--) begin
            if (data_in < pow10(i))
                digs_out = i;
        end
    end

endmodule