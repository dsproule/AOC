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

module mod #(
    parameter mod_div = 2
)(
    input logic [`DATA_WIDTH-1:0] data_in,

    output logic [$clog2(mod_div)-1:0] mod_out
);

    generate 
        if (mod_div == 2)
            assign mod_out = data_in[0];
        else if (mod_div == 4)
            assign mod_out = data_in[1:0];
        else if (mod_div == 8)
            assign mod_out = data_in[2:0];
        else 
            assign mod_out = 0;
    endgenerate
endmodule