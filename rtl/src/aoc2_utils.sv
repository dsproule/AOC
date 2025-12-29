`include "common.svh"

module get_digs(
    input logic [`DATA_WIDTH-1:0] n_in,

    output logic [3:0] digs_out
);

    genvar i;
    always_comb begin
        digs_out = 1;
        for (int i = 10; i > 0; i--) begin
            if (n_in < pow10(i))
                digs_out = i;
        end
    end

endmodule

module pref_lookup(
    input logic [3:0] idx,  // 0-10 needs 4 bits

    output logic [`LONG_DATA_WIDTH-1:0] value
);

    always_comb begin
        case (idx)
            4'd0:  value = 64'd0;
            4'd1:  value = 64'd0;
            4'd2:  value = 64'd495;
            4'd3:  value = 64'd5490;
            4'd4:  value = 64'd500895;
            4'd5:  value = 64'd1000890;
            4'd6:  value = 64'd540590850;
            4'd7:  value = 64'd590590845;
            4'd8:  value = 64'd495095086350;
            4'd9:  value = 64'd990140130900;
            4'd10: value = 64'd496436044631310;
            default: value = 64'd0;
        endcase
    end

endmodule